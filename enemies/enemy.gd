@abstract class_name Enemy
extends CharacterBody2D

#initalize in editor
@export var patrol: Array[Vector2]
var patrol_index: int
var walk_speed: float

var los_area : Area2D
var los_cone_deg: float
var los_distance: int

# 0:neutral  1:combat
var combat_state: bool
# 0:static  1:moving
var is_patroling: bool	


func ready():
	combat_state= false
	read_enemy_data("generic_enemy_parameters")
	los_area = get_node("SkeletonLoS")

	#establish if enemy will patrol or stay put
	if (patrol.size() > 1):
		patrol_index = 1
		is_patroling = true
	else: is_patroling = false
	
func _physics_process(delta : float):
	var detected_bodies : Array[Node2D] = los_area.get_overlapping_bodies()
	for body in detected_bodies:
		if (body.name == "Penny") or (body.name.contains("Slime")):
			combat_state = true
			is_patroling = false
	if is_patroling:
		return
	elif combat_state:
		attack()
		combat_state = false
		is_patroling = true
	
	return
	
func _on_body_entered():
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
	#draw polygon for enemy line of sight, can refactor to accept args instead of reading value from settings.cfg
	var cone = CollisionPolygon2D.new()
	var y_offset : int = int(tan(los_cone_deg * (PI/180)) * los_distance)
	cone.polygon= PackedVector2Array([Vector2(0,0), Vector2(los_distance, y_offset), Vector2(los_distance, -y_offset)])
	
	los_area.add_child(cone)

@abstract 
func attack()

	
