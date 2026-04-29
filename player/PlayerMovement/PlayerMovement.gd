@abstract class_name PlayerMovement
extends CharacterBody2D

# Sent to Scene Manager whenever a player character dies, to reset the scene
signal penny_died

var health: int
# While at present no character class has use for the amount of time since the past physics frame, when more interesting
# game behavior is added later, it's likely to be useful, so I'm putting it as an optional parameter for all movement functions.
# To make the delta mandantory, just delete the default value

# Movement parameters
var mass: float
var run_max_velocity: float
var run_acceleration: float
var run_deceleration: float
var jump_velocity: float
var climb_max_speed: float
var terminal_velocity: float
var coyote_time: float
var fluid_buoyancy: float
var fluid_drag: Vector2
var fluid_entry_dampening: Vector2
var fluid_drying_time: float

# Count the number of tar globs intersecting with this slime
var tar_intersections: int

# Screen bounds
var screen: Vector2

# Target we will interact with when we press the interact button, if any
var interaction_target: InteractionTarget = null

var coyote_timer: Timer = null
var hover_timer: Timer = null

# Net effects of fluid volumes we're currently in, applied in physics_process
var wetness: float = 0
var num_fluid_volumes: int = 0
var net_fluid_velocity: Vector2 = Vector2.ZERO
var effective_fluid_velocity: Vector2 = Vector2.ZERO  # Cached fluid velocity for use while we're drying

# Whether this slime should have elastic collisions with static bodies (e.g. true for ice slime to bounce off walls)
func isElastic() -> bool:
	return false

# Whether this character can currently interact with things (e.g. always false for ice slime)
# If this changes at some point, the child script must alert any interaction targets in the area
func canInteract() -> bool:
	return true

# Returns true iff this player object can climb right now (i.e. is in tar and against a wall)
func canClimb(direction: float):
	if(tar_intersections > 0 and is_on_wall()):
		var wall_direction = get_wall_normal()
		if(wall_direction.x * direction < 0):
			return true
	return false


func climb(direction: float, delta: float):
	# Climbing slimes move orthogonally to the wall normal
	var floor_direction = get_wall_normal().orthogonal()
	# If the magnitude of this vector is exceeded, then we consider this too fast
	var target_velocity = velocity - floor_direction * direction * run_acceleration * delta
	velocity = target_velocity
	velocity.y = max(velocity.y, climb_max_speed)
	velocity.y = min(velocity.y, terminal_velocity)
	velocity.x = max(velocity.x, -run_max_velocity)
	velocity.x = min(velocity.x, run_max_velocity)
	if(abs(velocity.x) == 0):
		velocity.x = direction
	
func setInteractionTarget(target: InteractionTarget) -> void:
	interaction_target = target

func clearInteractionTarget(target: InteractionTarget) -> void:
	if interaction_target == target:
		interaction_target = null
# Do whatever this character does when hit (split if slime, take damage otherwise)
@abstract func hit()

# Defined so that PlayerMovement instances can be pushed by eachother
func getMass() -> float:
	return mass

func enterFluidVolume(fluid_velocity: Vector2) -> void:
	num_fluid_volumes += 1
	net_fluid_velocity += fluid_velocity

	# Dampen the incoming velocity if we are entering a volume
	if num_fluid_volumes == 1:
		velocity *= fluid_entry_dampening

func exitFluidVolume(fluid_velocity: Vector2) -> void:
	num_fluid_volumes -= 1
	net_fluid_velocity -= fluid_velocity

# Take an arbitrary amount of damage
func takeDamage(damage = 1):
	health -= damage
	if(health <= 0):
		die()


# This player character died, so the game needs to reset
func die():
	penny_died.emit()


# Abstract method for defining fluid interactions
# Triggered when a fluid emitter hits this character, with the fluid type of the emitter
func onFluidHit(_fluid_type: FluidFlow.Type) -> void:
	pass

# Move along the ground or in the air
func move(direction: float, delta: float) -> void:
	#regular footstep by default
	var desired_step_sfx : String = "footstep"
	if(canClimb(direction)):
		climb(direction, delta)
	else:
		var run_velocity = direction * run_max_velocity
		# If we're moving with the fluid, dampen max velocity so it doesn't get effectively doubled
		if wetness > 0 and sign(direction) == sign(effective_fluid_velocity.x):
			run_velocity *= (1 - wetness)
			desired_step_sfx = "fluid_footstep"

		# Move towards the target velocity (plus net fluid flows)
		var target_velocity = run_velocity + effective_fluid_velocity.x * wetness
		velocity.x = move_toward(velocity.x, target_velocity, run_acceleration * delta)
		if InputManager.get_is_human():
			AudioManager.play_sfx(desired_step_sfx, 1)

# To implement sliding later, we likely want to pass a delta to this function
func stop(delta: float) -> void:
	# Decelerate towards zero (relative to the fluid velocity if we're in a fluid)
	var target_velocity = effective_fluid_velocity.x * wetness

	# Deceleration is slower when in a fluid
	var deceleration = run_deceleration * (1.0 - wetness * fluid_drag.x)

	velocity.x = move_toward(velocity.x, target_velocity, deceleration * delta)

# Make this player-controlled character jump, if it can
func jump(delta: float) -> void:
	velocity.y = jump_velocity

# Determine player-controlled character behavior in free fall
func fall(delta: float) -> void:
	# If the hover timer is running, don't apply gravity
	if not hover_timer.is_stopped():
		return

	# We assume gravity only affects the y component lol
	velocity.y = move_toward(velocity.y, terminal_velocity, get_gravity().y * delta)

var config = ConfigFile.new()
func _ready() -> void:
	tar_intersections = 0
	screen = get_viewport_rect().size
	# Attempt to read movement settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read movement settings from settings.cfg")
	penny_died.connect(SceneManager.resetScene)
	# Read movement defaults
	read_movement_data("movement_defaults")

	coyote_timer = Timer.new()
	coyote_timer.wait_time = coyote_time
	coyote_timer.one_shot = true
	add_child(coyote_timer)

	# Set up timer for midair hover
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	add_child(hover_timer)


# Loads movement options
func read_movement_data(my_name):
	mass = config.get_value(my_name, "mass", mass)
	run_max_velocity = config.get_value(my_name, "run_max_velocity", run_max_velocity)
	run_acceleration = config.get_value(my_name, "run_acceleration", run_acceleration)
	run_deceleration = config.get_value(my_name, "run_deceleration", run_deceleration)
	climb_max_speed = config.get_value(my_name, "climb_max_velocity", climb_max_speed)
	jump_velocity = config.get_value(my_name, "jump_velocity", jump_velocity)
	terminal_velocity = config.get_value(my_name, "terminal_velocity", terminal_velocity)
	coyote_time = config.get_value(my_name, "coyote_time", coyote_time)
	fluid_buoyancy = config.get_value(my_name, "fluid_buoyancy", fluid_buoyancy)
	fluid_drag = config.get_value(my_name, "fluid_drag", fluid_drag)
	fluid_entry_dampening = config.get_value(my_name, "fluid_entry_dampening", fluid_entry_dampening)
	fluid_drying_time = config.get_value(my_name, "fluid_drying_time", fluid_drying_time)


# Modify logic here to change controls for all slimes and Penny
func _physics_process(delta: float) -> void:
	if not SceneManager.physics_applies:
		return

	# Check if player is OOB, and reset to origin if so
	if position.x >= screen.x or position.y >= screen.y:
		die()

	# Add the gravity.
	if not is_on_floor():
		fall(delta)
	else:
		coyote_timer.start()

	# Handle jump.
	if Input.is_action_just_pressed("jump") and !coyote_timer.is_stopped():
		jump(delta)
		coyote_timer.stop()

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		move(direction, delta)
	else:
		stop(delta)

	# Handle interaction
	if Input.is_action_just_pressed("interact") and interaction_target:
		interaction_target.interact(self)

	# Apply fluid forces
	if num_fluid_volumes > 0:
		wetness = 1.0
		effective_fluid_velocity = net_fluid_velocity
	else:
		wetness = move_toward(wetness, 0, delta / fluid_drying_time)

	if wetness > 0:
		# Buoyancy just directly negates part of gravity
		if not is_on_floor():
			velocity.y -= get_gravity().y * fluid_buoyancy * delta * wetness

		# Get our velocity relative to the fluid for drag calculations
		var relative_velocity = velocity - effective_fluid_velocity

		# Stokes (linear) drag for the horizontal component
		if relative_velocity.x != 0:
			var drag_delta = relative_velocity * fluid_drag * delta * wetness
			velocity.x = move_toward(velocity.x, effective_fluid_velocity.x, abs(drag_delta.x))

		# We only apply Newtonian (quadratic) drag to the vertical component because horizontal
		# movement would be unevenly affected with varying max vel/accel of slimes vs Penny
		if relative_velocity.y != 0:
			var drag_delta = (relative_velocity * relative_velocity.abs()) * fluid_drag * delta * wetness
			velocity.y = move_toward(velocity.y, effective_fluid_velocity.y, abs(drag_delta.y))

	var pre_slide_velocity = velocity
	move_and_slide()

	# Push things
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider:
			var normal = collision.get_normal()

			# Ignore downward force
			if normal.y < -.1: continue

			var impact_velocity = pre_slide_velocity.project(-normal)

			if collider is CharacterBody2D and collider.has_method('getMass'):
				# Fix losing jump below another slime: if we jumped and were blocked by a slime in move_and_slide, reapply our vertical velocity
				if normal.y > .1 and pre_slide_velocity.y < 0:
					# Transfer our velocity and reset to what it was
					collider.velocity.y = min(collider.velocity.y, pre_slide_velocity.y)
					velocity.y = pre_slide_velocity.y
					continue

				# Prevent re-pushing if the slimes are already bouncing apart
				var is_approaching = sign(pre_slide_velocity.x - collider.velocity.x) == sign(collider.global_position.x - global_position.x)
				if not is_approaching:
					continue

				# Elastic collisions
				var m1 = mass
				var m2 = collider.getMass()
				var v1 = pre_slide_velocity.x
				var v2 = collider.velocity.x
				var M = (m1 - m2) / (m1 + m2)
				velocity.x = M * v1 + (2 * m2 / (m1 + m2)) * v2
				collider.velocity.x = (2 * m1 / (m1 + m2)) * v1 - M * v2

			elif collider is RigidBody2D:
				# Impulse is F*time
				var impulse = impact_velocity * mass
				collider.apply_central_impulse(impulse)

				# Bounce away from the rigidbody if we are an elastic collider
				if isElastic() and abs(normal.x) > 0.1:
					velocity.x = -pre_slide_velocity.x

			elif isElastic() and (collider is StaticBody2D or collider is TileMapLayer) and abs(normal.x) > 0.1:
				velocity.x = -pre_slide_velocity.x

	# Start the hover timer if we hit the ceiling
	if pre_slide_velocity.y < 0 and is_on_ceiling():
		# Figure out how much time we have to the apex of our jump
		var time_to_apex = -pre_slide_velocity.y / get_gravity().y

		if time_to_apex > 0:
			velocity.y = 0
			hover_timer.start(time_to_apex)
