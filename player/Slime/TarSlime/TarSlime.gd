extends Slime

func _ready():
	hitbox_name = "TarSlime"
	sprite_name = "tar-slime"
	movement_name = "tar_slime_movement"
	slime_type = Slime.Type.GREEN_SLIME
	super()
	health = config.get_value("slime_health", "green_slime")

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = (size / 4.0 + 6) / (8.0)
	# Do not multiply attributes by size multiplier directly, or else slimes that have merged and unmerged multiple times
	# will have different attributes since one of them is technically the same entity, just with a different hitbox and texture
	mass = base_mass * mul
	run_max_velocity = base_run_max_velocity * mul
	run_acceleration = base_run_acceleration * mul
	run_deceleration = base_run_deceleration * mul
	jump_velocity = base_jump_velocity * mul
