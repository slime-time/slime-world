class_name RangedSkeleton
extends "res://enemies/enemy.gd"

func ready():
    super()
    
    # Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
    #read values from settings.cfg
    read_ranged_data("ranged_parameters")

func read_ranged_data(sectionName):
    

func attack():