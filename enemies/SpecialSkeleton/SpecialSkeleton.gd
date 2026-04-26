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
