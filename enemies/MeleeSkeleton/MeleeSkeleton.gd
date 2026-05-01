class_name MeleeSkeleton
extends Skeleton

var attack_trigger: Node2D
var attack_hitbox: Node2D

var players_hittable: Array[Node2D]

var physics_delta: float

# True only when the skeleton hasn't hit anything during the current animation	
var can_hit: bool
func _physics_process(delta: float):
	physics_delta = delta
	super(delta)

func _ready():
	super()
	sprite = get_node("MeleeSprite")
	sprite.animation_changed.connect(func():
		sprite.play()
		can_hit = true
	)
	sprite.set_animation("idle")
	
	attack_trigger = get_node("AttackTrigger")
	attack_hitbox = get_node("AttackHitbox")
	attack_trigger.body_entered.connect(targetForAttack)
	attack_trigger.body_exited.connect(untargetForAttack)
	attack_hitbox.body_entered.connect(throw_water)
	set_los_cone()

func targetForAttack(target: Node2D):
	if(target is PlayerMovement):
		players_hittable.append(target)
		
func untargetForAttack(target: Node2D):
	if(target in players_hittable):
		players_hittable.erase(target)
		
func read_melee_data(_sectionName):
	var config = ConfigFile.new()
	# Attempt to read melee enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	
	return

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
			if(sprite.animation == "attack"):
				sprite.set_animation("idle")
		, CONNECT_ONE_SHOT)
	
	#wait again so that the player can exploit a whiff or position enemies intentionally
	
func hit():
	super()
	var chunk1 = get_node("AttackHitbox/Chunk1")
	var chunk2 = get_node("AttackHitbox/Chunk2")
	attack_hitbox.set_monitoring(false)
	attack_hitbox.set_visible(false)
	chunk1.set_deferred("disabled", true)
	chunk2.set_deferred("disabled", true)
	
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

func combat_behavior():
	if(stop_timer.is_stopped() and players_hittable.size() == 0):
		sprite.set_animation("walk")
		if (is_instance_valid(combat_target)):
			if(combat_target.global_position.x < global_position.x):
				velocity.x = move_toward(velocity.x, -walk_speed, (physics_delta * 1000) / 16)
			else:
				velocity.x = move_toward(velocity.x, walk_speed, (1000 * physics_delta) / 16)
	elif(stop_timer.is_stopped()):
		attack()
	
func throw_water(target : Node2D):
	if (target is PlayerMovement) and combat_state and can_hit:
		var bodies = attack_trigger.get_overlapping_bodies()
		for body in bodies:
			if(body is PlayerMovement):
				body.hit()
				can_hit = false


func set_hitbox_state():
	if sprite.animation == "attack" and sprite.frame == 6:
		AudioManager.play_sfx("swordswing", 1, -0.2)
		attack_hitbox.set_monitoring(true)
		attack_hitbox.set_visible(true)
	elif sprite.animation == "attack" and sprite.frame == 10:
		attack_hitbox.set_monitoring(false)
		attack_hitbox.set_visible(false)
		return
	if (not get_tree().process_frame.is_connected(set_hitbox_state) and sprite.animation == "attack"):
		get_tree().process_frame.connect(set_hitbox_state, CONNECT_ONE_SHOT)
