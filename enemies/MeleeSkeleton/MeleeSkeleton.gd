class_name MeleeSkeleton
extends Skeleton


var attack_hitbox: Area2D

func _ready():
	super()
	set_los_cone()
	
	sprite = get_node("MeleeSprite")
	sprite.set_autoplay("idle")
	sprite.play()
	sprite.animation_changed.connect(sprite.play)
	
	attack_hitbox = get_node("AttackHitbox")
	attack_hitbox.body_entered.connect(attack)
	read_melee_data("melee_parameters")
	


func read_melee_data(sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	return

func combat_behavior():
	velocity.x =  move_toward(velocity.x, walk_speed * ((combat_target.global_position.x - position.x ) / abs(combat_target.global_position.x - position.x)), 1)

func turnaround():
	if !sprite.flip_h:
		sprite.flip_h = true
		los_area.scale.x = -1
	else:
		sprite.flip_h = false
		los_area.scale.x = 1
	attack_hitbox.position.x = -attack_hitbox.position.x
	
	return

func attack(target : Node2D):
	#stop
	velocity.x = 0
	
	if (target is PlayerMovement) and combat_state:
		sprite.set_animation("attack")
		target.hit()
		
		
	return
	
