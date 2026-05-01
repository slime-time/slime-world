class_name MeleeSkeleton
extends Skeleton


var attack_trigger: Area2D
var attack_hitbox: Area2D

func _ready():
	super()
	set_los_cone()
	sprite = get_node("MeleeSprite")
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
	position.x = move_toward(position.x, combat_target.global_position.x, walk_speed)

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
	if (target is PlayerMovement) and combat_state:
		#play animation and confirm hit
		target.hit()
		
		#play animation and set hitboxes to active through animation_changed/frame_changed signals
		if (target is PlayerMovement):
			sprite.set_animation("attack")
		
		#wait again so that the player can exploit a whiff or position enemies intentionally
		stop_timer.start()	
	
		return
	
func deal_damage(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		target.hit()
		#force despawn of hitboxes so that slime is only split once
		attack_hitbox.set_monitoring(false)
		attack_hitbox.set_visible(false)
	
func set_hitbox_state():
	if sprite.animation == "attack" and sprite.frame == 6:
		attack_hitbox.set_monitoring(true)
		attack_hitbox.set_visible(true)
	elif sprite.animation == "attack" and sprite.frame == 10:
		attack_hitbox.set_monitoring(false)
		attack_hitbox.set_visible(false)
