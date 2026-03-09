@abstract class_name PlayerMovement
extends CharacterBody2D

# Sent to Scene Manager whenever a player character dies, to reset the scene
signal penny_died

var health: int
# While at present no character class has use for the amount of time since the past physics frame, when more interesting
# game behavior is added later, it's likely to be useful, so I'm putting it as an optional parameter for all movement functions.
# To make the delta mandantory, just delete the default value

# Movement parameters
var run_max_velocity: float
var run_acceleration: float
var run_deceleration: float
var jump_velocity: float
var terminal_velocity: float

# Screen bounds
var screen: Vector2

# Do whatever this character does when hit by a spike (split if slime, take damage otherwise)
@abstract func spikeHit()

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
	# Move towards the target velocity
	var target_velocity = direction * run_max_velocity
	velocity.x = move_toward(velocity.x, target_velocity, run_acceleration * delta)

# To implement sliding later, we likely want to pass a delta to this function
func stop(delta: float) -> void:
	# Decelerate towards zero
	velocity.x = move_toward(velocity.x, 0, run_deceleration * delta)

# Make this player-controlled character jump, if it can
func jump(delta: float) -> void:
	velocity.y = jump_velocity

# Determine player-controlled character behavior in free fall
func fall(delta: float) -> void:
	# We assume gravity only affects the y component lol
	velocity.y = move_toward(velocity.y, terminal_velocity, get_gravity().y * delta)

var config = ConfigFile.new()
func _ready() -> void:
	screen = get_viewport_rect().size
	# Attempt to read movement settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read movement settings from settings.cfg")
	penny_died.connect(SceneManager.resetScene)
	# Read movement defaults
	read_movement_data("movement_defaults")


# Loads movement options
func read_movement_data(my_name):
	run_max_velocity = config.get_value(my_name, "run_max_velocity", run_max_velocity)
	run_acceleration = config.get_value(my_name, "run_acceleration", run_acceleration)
	run_deceleration = config.get_value(my_name, "run_deceleration", run_deceleration)
	jump_velocity = config.get_value(my_name, "jump_velocity", jump_velocity)
	terminal_velocity = config.get_value(my_name, "terminal_velocity", terminal_velocity)


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

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump(delta)

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		move(direction, delta)
	else:
		stop(delta)

	move_and_slide()
