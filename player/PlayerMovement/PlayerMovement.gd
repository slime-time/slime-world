@abstract class_name PlayerMovement
extends CharacterBody2D

# While at present no character class has use for the amount of time since the past physics frame, when more interesting
# game behavior is added later, it's likely to be useful, so I'm putting it as an optional parameter for all movement functions.
# To make the delta mandantory, just delete the default value

# Movement parameters
var run_max_velocity: float
var run_base_acceleration: float
var run_base_deceleration: float
var run_jerk: float
var jump_velocity: float

# Active movement acceleration
var run_acceleration: float = 0

# Screen bounds
var screen: Vector2

# TODO: movement is mathematically incorrect because we're not applying velocity
# 		changes as they should have been before our accel updates over delta time
# 		we'll fix it later lol

# Move along the ground or in the air
func move(direction: float, delta: float) -> void:
	# Apply the base acceleration
	if signf(direction) != signf(velocity.x):
		run_acceleration = direction * run_base_acceleration

	# Apply jerk
	run_acceleration += direction * run_jerk * delta

	# Update velocity and clamp it
	velocity.x = clampf(velocity.x + run_acceleration * delta, -run_max_velocity, run_max_velocity)

# To implement sliding later, we likely want to pass a delta to this function
func stop(delta: float) -> void:
	# If velocity and acceleration have the same sign, we were still accelerating
	if signf(run_acceleration) == signf(velocity.x):
		run_acceleration = (-signf(velocity.x)) * run_base_deceleration

	# Apply jerk to deceleration
	run_acceleration += signf(run_acceleration) * run_jerk * delta
	
	# If we would go past zero, just zero the velocity and acceleration
	if abs(run_acceleration * delta) > abs(velocity.x):
		velocity.x = 0
		run_acceleration = 0
		return

	# Otherwise, apply acceleration to velocity
	velocity.x = velocity.x + run_acceleration * delta

# Make this player-controlled character jump, if it can
func jump(delta: float) -> void:
	velocity.y = jump_velocity

# Determine player-controlled character behavior in free fall
func fall(delta: float) -> void:
	velocity += get_gravity() * delta


# Coordinates that Penny should respawn to - should be updated with each screen / level change
var respawn_location = Vector2(-3, 56)

var config = ConfigFile.new()
func _ready() -> void:
	screen = get_viewport_rect().size
	# Attempt to read movement settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read movement settings from settings.cfg")


# Loads movement options 
func read_movement_data(my_name):
	run_max_velocity = config.get_value(my_name, "run_max_velocity")
	run_base_acceleration = config.get_value(my_name, "run_base_acceleration")
	run_base_deceleration = config.get_value(my_name, "run_base_deceleration")
	run_jerk = config.get_value(my_name, "run_jerk")
	jump_velocity = config.get_value(my_name, "jump_velocity")


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
