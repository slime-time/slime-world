
extends "res://player/Slime/Slime.gd"

func _ready():
	super()
	# Temporarily make green slime and Penny identical for now
	read_movement_data("penny_movement")
	getMovementAbility()
	health = config.get_value("slime_health", "green_slime")

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	run_max_velocity *= size / 8
	run_acceleration *= size / 8	# TODO: maybe should be inverted?
	run_deceleration *= size / 8	#		^ same here
	jump_velocity *= size / 8
