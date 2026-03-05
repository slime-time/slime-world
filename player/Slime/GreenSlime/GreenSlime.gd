
extends "res://player/Slime/Slime.gd"

func _ready():
	super()
	read_movement_data("green_slime_movement")
	getMovementAbility()

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	run_max_velocity *= size / 8
	run_base_acceleration *= size / 8
	run_jerk *= size / 8
	jump_velocity *= size / 8
