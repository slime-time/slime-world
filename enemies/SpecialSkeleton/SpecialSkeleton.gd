class_name SpecialSkeleton
extends Skeleton

@export
var fluid_type : FluidFlow.Type
#set in editor

var attack_trigger : Area2D
var attack_hitbox: Area2D

func _ready():
	super()
	sprite = get_node("SpecialSprite")
	sprite.animation_changed.connect(sprite.play)
	sprite.set_animation("idle")
	
	attack_trigger = get_node("AttackTrigger")
	attack_hitbox = get_node("AttackHitbox")
	attack_trigger.body_entered.connect(attack)
	attack_hitbox.body_entered.connect(throw_water)
	
	match fluid_type:
		#add more types
		FluidFlow.Type.WATER:
			#load water bucket sprite
			print("placeholder")
		FluidFlow.Type.ICE_WATER:
			#load ice water bucket sprite
			print("placeholder")
		FluidFlow.Type.TAR:
			#load ice water bucket sprite
			print("placeholder")
	
	set_los_cone()

func attack(target : Node2D):
	#stop 
	velocity.x = 0
	stop_timer.start()
	
	#play animation and set hitboxes to active through animation_changed/frame_changed signals
	if (target is PlayerMovement) and combat_state:
		sprite.set_animation("attack")
		set_hitbox_state()
	
	#wait again so that the player can exploit a whiff or position enemies intentionally
	stop_timer.start()	
		
	return
	
func throw_water(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		var bodies = attack_trigger.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("onFluidHit"):
				body.onFluidHit(fluid_type)

func combat_behavior():
	print_debug("called combat")
	if(stop_timer.is_stopped() and is_patroling):
		velocity.x =  move_toward(velocity.x, walk_speed * ((combat_target.global_position.x - position.x ) / abs(combat_target.global_position.x - position.x)), 1)
	elif(stop_timer.is_stopped()):
		attack(combat_target)

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

func set_hitbox_state():
	var chunk1 = get_node("AttackHitbox/Chunk1")
	var chunk2 = get_node("AttackHitbox/Chunk2")
	if sprite.animation == "attack" and sprite.frame == 7:
		attack_hitbox.set_monitoring(true)
		attack_hitbox.set_visible(true)
		chunk1.set_deferred("disabled", false)
		chunk1.set_visible(true)
		AudioManager.play_sfx("waterdump", 1)
	elif sprite.animation == "attack" and sprite.frame == 10:
		chunk1.set_deferred("visible", false)
		chunk2.set_deferred("visible", true)
		chunk1.set_deferred("disabled", true)
		chunk2.set_deferred("disabled", false)
	elif sprite.animation == "attack" and sprite.frame == 12:
		attack_hitbox.set_monitoring(false)
		attack_hitbox.set_visible(false)
		chunk1.set_visible(false)
		chunk2.set_visible(false)
		return
	get_tree().process_frame.connect(set_hitbox_state, CONNECT_ONE_SHOT)
