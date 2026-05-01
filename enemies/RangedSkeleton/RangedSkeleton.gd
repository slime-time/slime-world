class_name RangedSkeleton
extends Skeleton

var Arrow = preload("res://enemies/RangedSkeleton/Arrow/Arrow.tscn")

var projectile_speed
var attack_frequency
var attack_timer : Timer
#sprite is facing right by default
var facingRight : bool = true

func _ready():
	super()
	read_ranged_data("ranged_parameters")
	set_los_cone()
	
	sprite = get_node("RangedSprite")
	sprite.animation_changed.connect(sprite.play)
	sprite.frame_changed.connect(shooting_handler)
	
	attack_timer = Timer.new()
	attack_timer.timeout.connect(attack_timer.stop)
	add_child(attack_timer)

func combat_behavior():
	#attack on an interval
	if attack_timer.is_stopped():
		attack(combat_target)
		

func attack(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		combat_target = target	
		sprite.set_animation("attack")
		attack_timer.start(attack_frequency)
		
	return
	
func shoot(offset, target):
	var projectile = Arrow.instantiate()
	projectile.target = target.global_position
	projectile.speed = projectile_speed
	projectile.global_position= Vector2(global_position.x + offset, global_position.y + 6)
	AudioManager.play_sfx("bowshot", 1 , -10.5)
	get_parent().add_child(projectile)
	
func shooting_handler():
	var offset
	if facingRight: offset = 10
	else: offset = -10
	if sprite.animation == "attack" and sprite.frame == 11:
		shoot(offset, combat_target)
	
#override
func _physics_process(_delta : float):
	#draw line of sight every frame
	set_los_cone()
	super(_delta)

#override
func turnaround():
	if facingRight:
		facingRight = false
		sprite.flip_h = true
	else:
		facingRight = true
		sprite.flip_h = false
	return
	
#override
func set_los_cone():
	#see if we need to raycast "infinitely" to the right or left
	var queryTarget
	var dynamicDistance
	if facingRight: queryTarget = get_viewport_rect().size.x
	else: queryTarget = 0
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, Vector2(queryTarget, position.y))
	query.exclude = [self, los_area]
	var result = space_state.intersect_ray(query)
	
	if(result): dynamicDistance = result.position.x
	else: return
		
	var cone = CollisionPolygon2D.new() 
	var origin : Vector2 = Vector2(position.x, position.y)
	var y_offset : int = int(tan(los_cone_deg * (PI/180)) * dynamicDistance)
	cone.polygon= PackedVector2Array([origin, Vector2(origin.x + dynamicDistance, origin.y + y_offset), 
	Vector2(origin.x + dynamicDistance, origin.y -y_offset)])
	
	los_area.add_child(cone)
	return

func read_ranged_data(sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	projectile_speed = config.get_value(sectionName, "projectile_speed", projectile_speed)
	attack_frequency = config.get_value(sectionName, "attack_frequency", attack_frequency)
	los_cone_deg = config.get_value(sectionName, "ranged_los_cone_deg", los_cone_deg)
