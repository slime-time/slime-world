class_name IceSlime
extends Slime

func _ready():
	hitbox_name = "IceSlime"
	sprite_name = "ice-slime"
	movement_name = "ice_slime_movement"
	slime_type = Slime.Type.ICE_SLIME
	super()
	health = config.get_value("slime_health", "ice_slime")

	# its like fine we can just do this aaaa
	set_collision_mask_value(Spike.SPIKE_COLLISION_LAYER, true)

# Get the movement ability of this specific slime (including size in calculation)
func getMovementAbility():
	var mul = 0
	mass = base_mass * (size / 8.0)
	run_max_velocity *= mul
	run_acceleration *= mul
	run_deceleration *= mul
	jump_velocity *= mul
	climb_max_speed = 0

func canInteract() -> bool:
	# Ice slime cannot interact with things
	return false

func isElastic() -> bool:
	# Ice slime has elastic collisions with walls and other static bodies
	return true
