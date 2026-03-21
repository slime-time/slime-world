
extends Slime

func _ready():
	hitbox_name = "IceSlime"
	sprite_name = "ice-slime"
	movement_name = "ice_slime_movement"
	slime_type = Slime.Type.ICE_SLIME
	super()
	health = config.get_value("slime_health", "ice_slime")

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = 0
	mass = base_mass * (size / 8.0)
	run_max_velocity *= mul
	run_acceleration *= mul
	run_deceleration *= mul
	jump_velocity *= mul
