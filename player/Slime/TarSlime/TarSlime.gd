extends Slime

var base_climb_max_speed
# Maximum speed this slime can climb up objects
var climb_max_speed
	
func move(direction: float, delta: float):
	if(is_on_wall()):
		# Tar slime moves orthogonally to the wall normal
		var floor_direction = get_wall_normal().orthogonal()
		# If the magnitude of this vector is exceeded, then we consider this 
		var target_velocity = velocity - floor_direction * direction * run_acceleration * delta
		velocity = target_velocity
		velocity.y = max(velocity.y, climb_max_speed)
		velocity.y = min(velocity.y, terminal_velocity)
		velocity.x = max(velocity.x, -run_max_velocity)
		velocity.x = min(velocity.x, run_max_velocity)
	else:
		super(direction, delta)
		
	


func read_movement_data(my_name):
	base_climb_max_speed = config.get_value(my_name, "climb_max_velocity", -50)
	super(my_name)

func _ready():
	hitbox_name = "TarSlime"
	sprite_name = "tar-slime"
	movement_name = "tar_slime_movement"
	slime_type = Slime.Type.TAR_SLIME
	super()
	health = config.get_value("slime_health", "tar_slime")


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
	climb_max_speed = base_climb_max_speed * mul
