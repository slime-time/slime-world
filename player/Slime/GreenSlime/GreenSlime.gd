
extends "res://player/Slime/Slime.gd"

func canBecomePenny():
	return size >= 8

func _ready():
	hitbox_name = "GreenSlime"
	sprite_name = "slime"
	movement_name = "green_slime_movement"
	super()
	health = config.get_value("slime_health", "green_slime")
	slime_type = Slime.Type.GREEN_SLIME

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = (size / 2.0 + 4) / 8.0
	run_max_velocity *= mul
	run_acceleration *= mul
	run_deceleration *= mul
	jump_velocity *= mul
