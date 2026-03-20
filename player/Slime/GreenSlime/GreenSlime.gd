
extends Slime

func canBecomePenny():
	return size >= 8

func _ready():
	hitbox_name = "GreenSlime"
	sprite_name = "slime"
	movement_name = "green_slime_movement"
	slime_type = Slime.Type.GREEN_SLIME
	super()
	health = config.get_value("slime_health", "green_slime")

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = (size / 2.0 + 4) / 8.0
	mass *= mul
	run_max_velocity = base_run_max_velocity * mul
	run_acceleration = base_run_acceleration * mul
	run_deceleration = base_run_deceleration * mul
	jump_velocity = base_jump_velocity * mul
