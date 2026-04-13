@abstract class_name Enemy
extends CharacterBody2D

#initalize in editor
@export var patrol: Array[Vector2]
var patrol_index: int
var walk_speed: float

var los_cone_deg: float
var los_distance: float

# 0:neutral  1:combat
var combat_state: bool
# 0:static  1:moving
var is_patroling: bool	


func ready():
	combat_state= false
	read_enemy_data("generic_enemy_parameters")

	#establish if enemy will patrol or stay put
	if (patrol.size() > 1):
		patrol_index = 1
		is_patroling = true
	else: is_patroling = false
	
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

@abstract 
func attack()

	
