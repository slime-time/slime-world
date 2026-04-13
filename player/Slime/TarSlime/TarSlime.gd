extends Slime

var base_climb_max_speed
# Maximum speed this slime can climb up objects
	
func canClimb(direction: float):
	if(is_on_wall()):
		var wall_direction = get_wall_normal()
		if(wall_direction.x * direction < 0):
			return true
	return false
	
const GLOB_TEMPLATE = preload("res://Tar/TarGlob/TarGlob.tscn")
func move(direction: float, delta: float):
	if(is_on_wall()):
		var wall_direction = get_wall_normal()
		if(wall_direction.x * direction < 0):
			var wallFinder = PhysicsRayQueryParameters2D.create(global_position, global_position - 20 * wall_direction)
			
			# The location the tar glob wants to go, without any coordinate smushing for the tar grid
			# Also useful information about whether or not the tar slime is actually touching a wall or
			# something else
			var tarGlobLocationRaw = get_world_2d().direct_space_state.intersect_ray(wallFinder)
			if(not tarGlobLocationRaw.size() == 0 and tarGlobLocationRaw.collider is TileMapLayer):
				var tarGlobLocation: Vector2i = TarManager.convertToCoordinates(tarGlobLocationRaw.position.x, global_position.y)
				var tarGlobIndex: int = TarManager.convertLocation(tarGlobLocation)
				# If there is no tar at that location, set the tar and make the tar object
				if(TarManager.checkLocation(tarGlobIndex)):
					TarManager.setLocation(tarGlobIndex)
					var tarGlob = GLOB_TEMPLATE.instantiate()
					tarGlob.set_global_position(Vector2(tarGlobLocation))
					get_tree().get_current_scene().add_child(tarGlob)
				
				
			climb(direction, delta)
		else:
			super(direction, delta)
	else:
		super(direction, delta)
		
	


func read_movement_data(my_name):
	base_climb_max_speed = config.get_value(my_name, "climb_max_velocity")
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
