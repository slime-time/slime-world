extends Slime

func _ready():
	hitbox_name = "EnergizedSlime"
	sprite_name = "energized-slime"
	movement_name = "green_slime_movement"
	slime_type = Slime.Type.ENERGIZED_SLIME
	super()
	health = config.get_value("slime_health", "energized_slime")

# Energized slime cannot merge, but splits whenever the merge button is pressed
func becomePenny():
	var old_size = size
	split(Slime.Type.GREEN_SLIME)
	# Only change the type of this slime if the splitting was successful
	if(size < old_size):
		slime_type_changed.emit(self, Slime.Type.GREEN_SLIME)

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = (size / 2.0 + 4) / (8.0)
	# Do not multiply attributes by size multiplier directly, or else slimes that have merged and unmerged multiple times
	# will have different attributes since one of them is technically the same entity, just with a different hitbox and texture
	mass = base_mass * mul
	run_max_velocity = base_run_max_velocity * mul
	run_acceleration = base_run_acceleration * mul
	run_deceleration = base_run_deceleration * mul
	jump_velocity = base_jump_velocity * mul
