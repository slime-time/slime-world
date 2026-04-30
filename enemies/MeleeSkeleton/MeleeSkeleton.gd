class_name MeleeSkeleton
extends Skeleton


var attack_trigger: Area2D
var attack_hitbox: Area2D

func _ready():
	super()
	
	sprite = get_node("MeleeSprite")
	sprite.animation_changed.connect(sprite.play)
	sprite.frame_changed.connect(set_hitbox_state)
	sprite.set_animation("idle")
	
	attack_trigger = get_node("AttackTrigger")
	attack_hitbox = get_node("AttackHitbox")
	attack_trigger.body_entered.connect(attack)
	attack_hitbox.body_entered.connect(deal_damage)
	read_melee_data("melee_parameters")
	
	set_los_cone()


func read_melee_data(sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	return

func combat_behavior():
	if(stop_timer.is_stopped()):
		velocity.x = move_toward(velocity.x, walk_speed * ((combat_target.global_position.x - position.x ) / abs(combat_target.global_position.x - position.x)), 1)
		did_collide = move_and_slide()
		if(did_collide):
			turnaround()

func turnaround():
	if !sprite.flip_h:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	los_area.scale.x = -los_area.scale.x
	attack_trigger.position.x = -attack_trigger.position.x
	attack_hitbox.position.x = -attack_hitbox.position.x
	attack_hitbox.scale.x = -attack_hitbox.scale.x
	
	return

func attack(target : Node2D):
		#stop
		velocity.x = 0
		sprite.stop()
		
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
		AudioManager.play_sfx("swordswing", 1)
		attack_hitbox.set_monitoring(true)
		attack_hitbox.set_visible(true)
	elif sprite.animation == "attack" and sprite.frame == 10:
		attack_hitbox.set_monitoring(false)
		attack_hitbox.set_visible(false)
