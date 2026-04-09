class_name Enemy
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


func _ready():
    combatState= false

    # Attempt to read enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
    #read values from settings.cfg
    read_enemy_data("generic_enemy_parameters")

    #establish if we will patrol or stay put
	if (patrol.size > 1):
        patrolIndex = 1
        isPatroling = true
    else: isPatroling = false
    
func read_enemy_data(sectionName):
    walk_speed= config.get_value(sectionName, "walk_speed", walk_speed)
    los_cone_deg= config.get_value(sectionName, "los_cone_deg", los_cone_deg)
    los_distance= config.get_value(sectionName, "los_distance", los_distance)

@abstract 
func attack():


	

