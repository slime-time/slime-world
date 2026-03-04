
extends "res://player/Slime/Slime.gd"

# The movement speed of a size 1 green slime
var baseline_movement_speed
# The jump velocity of a size 1 green slime
var baseline_jump_velocity
func _ready():
	super()
	read_movement_data("green_slime_movement")
	baseline_movement_speed = movement_speed
	baseline_jump_velocity = jump_velocity
	getMovementAbility()
	
# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	movement_speed = baseline_movement_speed * size
	jump_velocity = baseline_jump_velocity * size
	
	
# Standard platformer controls: green slime should control similarly to human form, but slightly
# faster and with much higher jump (at maximum size)
func move(direction, _delta = null):
	velocity.x = direction * movement_speed
	
func jump(_delta = null):
	velocity.y = jump_velocity
	
func stop(_delta = null):
	velocity.x = 0
	
func fall(delta = null):
	velocity += get_gravity() * delta
	
