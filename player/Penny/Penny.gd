extends "res://player/PlayerMovement/PlayerMovement.gd"

	
func _ready():
	super()
	read_movement_data("penny_movement")
	
# For now, implement very simple versions of movement. If you have a mind for design, please feel free to play around with these :3

func jump(_delta = null):
	velocity.y = jump_velocity
func fall(delta = null):
	velocity += get_gravity() * delta

func move(direction, _delta = null):
	velocity.x = direction * movement_speed
	
func stop(_delta = null):
	velocity.x = move_toward(velocity.x, 0, movement_speed)
	
