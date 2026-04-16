class_name MeleeSkeleton
extends Enemy

var stop : int
var sprite

func _ready():
	super()
	read_melee_data("melee_parameters")
	sprite = get_node("MeleeSprite")
	#establish if melee enemy will patrol or stay put until player is encountered
	if (patrol.size() > 1):
		is_patroling = true
		patrol_index = 1
	else: is_patroling = false
	stop = 0
	
func _physics_process(_delta : float):
	if stop:
		stop -= 1
		return
	
	if is_patroling:
		position.x = move_toward(position.x, float(patrol[patrol_index].x), walk_speed)
		
		if position.x == patrol[patrol_index].x:
			velocity.x = 0
			patrol_index = (patrol_index + 1) % patrol.size()
			#wait 10 frames
			stop = 10
			#reorient sprite and hitbox if necessary
			if ((patrol[patrol_index].x - global_position.x) < 0 and !sprite.flip_h) or ((patrol[patrol_index].x - global_position.x) > 0 and sprite.flip_h):
				await turnaround()
			
	elif combat_state:
		position.x = move_toward(position.x, combat_target.position.x, walk_speed)

	return

func read_melee_data(sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	return

func turnaround():
	if !sprite.flip_h:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	attack_hitbox.position.x = -attack_hitbox.position.x
	return

func deaggro(target : Node2D ):
	if target is PlayerMovement:
			combat_target = null
			combat_state = false
			#reorient sprite and hitbox if necessary
			if ((patrol[patrol_index].x - global_position.x) < 0 and !sprite.flip_h) or ((patrol[patrol_index].x - global_position.x) > 0 and sprite.flip_h):
				await turnaround()
	return

func attack(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		#play animation
		target.hit()
	return
	
