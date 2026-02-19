extends CharacterBody2D


var movement_speed = 300.0
var jump_velocity = -400.0
var screen

var config = ConfigFile.new()
func _ready() -> void:
	screen = get_viewport_rect().size
	
	# Attempt to read movement settings from an external file
	var error = config.load("res://settings.cfg")
	if(error == OK):
		movement_speed = config.get_value("penny_movement", "movement_speed")
		jump_velocity = config.get_value("penny_movement", "jump_velocity")

func _physics_process(delta: float) -> void:
	# Check if player is OOB, and reset to origin if so
	if position.x >= screen.x or position.y >= screen.y:
		position = Vector2.ZERO
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)

	move_and_slide()
