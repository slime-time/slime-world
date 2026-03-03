@abstract class_name PlayerMovement
extends CharacterBody2D

# While at present no character class has use for the amount of time since the past physics frame, when more interesting
# game behavior is added later, it's likely to be useful, so I'm putting it as an optional parameter for all movement functions.
# To make the delta mandantory, just delete the default value

# Move along the ground or in the air
@abstract func move(direction, delta = null)

# To implement sliding later, we likely want to pass a delta to this function
@abstract func stop(delta = null)

# Make this player-controlled character jump, if it can
@abstract func jump(delta = null)

# Determine player-controlled character behavior in free fall
@abstract func fall(delta)

var movement_speed
var jump_velocity
var screen

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
	movement_speed = config.get_value(my_name, "movement_speed")
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
		move(direction)
	else:
		stop(delta)
	
	move_and_slide()
