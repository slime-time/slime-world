class_name MeleeSkeleton
extends "res://enemies/enemy.gd"

var hitbox_radius: float

func ready():
    super()
    
    # Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
    #read values from settings.cfg
    read_melee_data("melee_parameters")

func read_melee_data(sectionName):


func attack():
	

