class_name RangedSkeleton
extends Skeleton

var projectile_speed
var attack_frequency
var attack_timer : Timer

func _ready():
	super()
	read_ranged_data("ranged_parameters")
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_frequency

func combat_behavior():
	#attack on an interval
	if attack_timer.is_stopped():
		attack(combat_target)
	else:
		attack_timer.start()

func attack(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		return
	return

func turnaround():
	if !sprite.flip_h:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	return
	
#override
func set_los_cone():
	return

func read_ranged_data(sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	walk_speed = config.get_value(sectionName, "projectile_speed", projectile_speed)
	los_cone_deg = config.get_value(sectionName, "attack_frequency", attack_frequency)
