@abstract class_name Skeleton
extends CharacterBody2D

#initalize in editor
@export var patrol: Array[Vector2]
var patrol_index: int
var walk_speed: float

var los_area : Area2D
var los_cone_deg: float
var los_distance: int

var attack_hitbox: Area2D
var combat_target: Node2D
# 0:neutral  1:combat
var combat_state: bool
# 0:static  1:patrolling
var is_patroling: bool	


func _ready():
	combat_state= false
	attack_hitbox = get_node("AttackHitbox")
	attack_hitbox.body_entered.connect(attack)
	
	los_area = get_node("SkeletonLoS")
	los_area.body_entered.connect(detect)
	los_area.body_exited.connect(deaggro)
	
	read_enemy_data("generic_enemy_parameters")
	set_los_cone()


	
func detect(target : Node2D ):
	if target is PlayerMovement:
			combat_target = target
			combat_state = true
			is_patroling = false
	return
	
func deaggro(target : Node2D ):
	if target is PlayerMovement:
			combat_target = null
			combat_state = false
			is_patroling = true
	return
	
func read_enemy_data(sectionName):
	var config = ConfigFile.new()
	
	# Attempt to read enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	#read values from settings.cfg
	walk_speed = config.get_value(sectionName, "walk_speed", walk_speed)
	los_cone_deg = config.get_value(sectionName, "los_cone_deg", los_cone_deg)
	los_distance = config.get_value(sectionName, "los_distance", los_distance)

func set_los_cone():
	var cone = CollisionPolygon2D.new() 
	var origin : Vector2 = Vector2(los_area.position.x, los_area.position.y)
	var y_offset : int = int(tan(los_cone_deg * (PI/180)) * los_distance)
	cone.polygon= PackedVector2Array([origin, Vector2(origin.x + los_distance, origin.y + y_offset), 
	Vector2(origin.x + los_distance, origin.y -y_offset)])
	
	los_area.add_child(cone)

@abstract 
func attack(target : Node2D)

	
