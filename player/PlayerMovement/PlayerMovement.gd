@abstract class_name PlayerMovement
extends CharacterBody2D

# Movement parameters
var run_max_velocity: float
var run_acceleration: float
var run_deceleration: float
var jump_velocity: float
var terminal_velocity: float

# Screen bounds
var screen: Vector2

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


# Coordinates that Penny should respawn to - should be updated with each screen / level change
var respawn_location = Vector2(-3, 56)

var config = ConfigFile.new()
func _ready() -> void:
	screen = get_viewport_rect().size
	# Attempt to read movement settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read movement settings from settings.cfg")
	
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
		velocity = Vector2.ZERO
		position = respawn_location

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
