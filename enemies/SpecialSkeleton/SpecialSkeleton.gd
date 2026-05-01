class_name SpecialSkeleton
extends Skeleton

@export
var fluid_type : FluidFlow.Type
#set in editor

var attack_hitbox : Area2D

func _ready():
	super()
	set_los_cone()
	sprite = get_node("SpecialSprite")
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

	attack_hitbox = get_node("AttackHitbox")
	attack_hitbox.body_entered.connect(attack)

func attack(target : Node2D):
	#play animation and confirm hit
	if (target is PlayerMovement) and combat_state:
		var bodies = attack_hitbox.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("onFluidHit"):
				body.onFluidHit(fluid_type)
		
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
	
func throw_water(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		var bodies = attack_hitbox.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("onFluidHit"):
				body.onFluidHit(fluid_type)

func combat_behavior():
	if(stop_timer.is_stopped() and is_patroling):
		velocity.x =  move_toward(velocity.x, walk_speed * ((combat_target.global_position.x - position.x ) / abs(combat_target.global_position.x - position.x)), 1)
		move_and_slide()
	

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
		chunk1.set_visible(true)
		chunk1.set_disabled(false)
	elif sprite.animation == "attack" and sprite.frame == 10:
		chunk1.set_visible(false)
		chunk1.set_disabled(true)
		chunk2.set_visible(true)
		chunk2.set_disabled(false)
	elif sprite.animation == "attack" and sprite.frame == 12:
		attack_hitbox.set_monitoring(false)
		chunk2.set_visible(false)
		chunk2.set_disabled(true)
