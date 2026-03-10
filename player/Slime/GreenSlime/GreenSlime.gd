
extends "res://player/Slime/Slime.gd"

func _ready():
	hitbox_name = "GreenSlime"
	sprite_name = "slime"
	movement_name = "green_slime_movement"
	super()
	health = config.get_value("slime_health", "green_slime")
	slime_type = Slime.Type.GREEN_SLIME

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	run_max_velocity *= size / 8.0
	run_acceleration *= size / 8.0	# TODO: maybe should be inverted?
	run_deceleration *= size / 8.0	#		^ same here
	jump_velocity *= size / 8.0
