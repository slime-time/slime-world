class_name SpecialSkeleton
extends Skeleton

@export
var fluid_type : FluidFlow.Type
#set in editor

var attack_trigger : Area2D
var attack_hitbox: Area2D

var SPRITE_SHEET: Array[Resource] = [
	preload("res://enemies/SpecialSkeleton/SpecialSkeletonSpriteSheets/ice.tres"),
	preload("res://enemies/SpecialSkeleton/SpecialSkeletonSpriteSheets/tar.tres"),
	preload("res://enemies/SpecialSkeleton/SpecialSkeletonSpriteSheets/water.tres"),
	preload("res://enemies/SpecialSkeleton/SpecialSkeletonSpriteSheets/woke.tres")
]
var players_hittable: Array[PlayerMovement]
  
var physics_delta: float

func _physics_process(delta: float):
	physics_delta = delta
	super(delta)

func _ready():
	super()
	sprite = get_node("SpecialSprite")
	sprite.animation_changed.connect(sprite.play)
	sprite.set_animation("idle")
	
	attack_trigger = get_node("AttackTrigger")
	attack_hitbox = get_node("AttackHitbox")
	attack_trigger.body_entered.connect(targetForAttack)
	attack_trigger.body_exited.connect(untargetForAttack)
	attack_hitbox.body_entered.connect(throw_water)
	
	match fluid_type:
		#add more types
		FluidFlow.Type.WATER:
			sprite.set_sprite_frames(SPRITE_SHEET[2])
			#load water bucket sprite
			
		FluidFlow.Type.ICE_WATER:
			#load ice water bucket sprite
			sprite.set_sprite_frames(SPRITE_SHEET[0])
		FluidFlow.Type.TAR:
			#load ice water bucket sprite
			sprite.set_sprite_frmaes(SPRITE_SHEET[1])
		FluidFlow.Type.ENERGIZED:
			sprite.set_sprite_frames(SPRITE_SHEET[3])
	set_los_cone()

func targetForAttack(target: Node2D):
	if(target is PlayerMovement):
		players_hittable.append(target)
	
func untargetForAttack(target: Node2D):
	if(target in players_hittable):
		players_hittable.erase(target)
		
func attack(_target = null):
	#play animation and set hitboxes to active through animation_changed/frame_changed signals
	if combat_state:
		#stop 
		velocity.x = 0
		sprite.set_animation("attack")
		#sprite.frame = 0
		set_hitbox_state()
		stop_timer.start()
		stop_timer.set_paused(true)
		sprite.animation_finished.connect(func():
			stop_timer.set_paused(false)
			velocity.x = 0
			sprite.set_animation("idle")
		, CONNECT_ONE_SHOT)
	
	#wait again so that the player can exploit a whiff or position enemies intentionally
	#stop_timer.start()	
		
	return
	
func throw_water(target : Node2D):
	if (target is PlayerMovement) and combat_state:
		var bodies = attack_trigger.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("onFluidHit"):
				body.onFluidHit(fluid_type)

func combat_behavior():
	if(stop_timer.is_stopped() and players_hittable.size() == 0):
		sprite.set_animation("walk")
		if(combat_target.global_position.x < global_position.x):
			velocity.x = move_toward(velocity.x, -walk_speed, (physics_delta * 1000) / 16)
		else:
			velocity.x = move_toward(velocity.x, walk_speed, (1000 * physics_delta) / 16)
	elif(stop_timer.is_stopped()):
		attack()

func turnaround():
	if !sprite.flip_h:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		
	los_area.scale.x = -los_area.scale.x
	attack_trigger.position.x = -attack_trigger.position.x
	attack_hitbox.position.x = -attack_hitbox.position.x
	attack_hitbox.scale.x = -attack_hitbox.scale.x
	hurtbox.position.x = - hurtbox.position.x
	return

func hit():
	super()
	var chunk1 = get_node("AttackHitbox/Chunk1")
	var chunk2 = get_node("AttackHitbox/Chunk2")
	attack_hitbox.set_monitoring(false)
	attack_hitbox.set_visible(false)
	chunk1.set_deferred("disabled", true)
	chunk2.set_deferred("disabled", true)

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
		chunk2.set_deferred("disabled", true)
		return
	if not (get_tree().process_frame.is_connected(set_hitbox_state)) and sprite.animation == "attack":
		get_tree().process_frame.connect(set_hitbox_state, CONNECT_ONE_SHOT)
