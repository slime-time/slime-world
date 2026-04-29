@abstract class_name Skeleton
extends CharacterBody2D

#initalize in editor
@export var patrol: Array[Node2D]
var patrol_index: int
var walk_speed: float
var sprite : AnimatedSprite2D


var hurtbox : CollisionShape2D

var los_area : Area2D
var los_cone_deg: float
var los_distance: int

var combat_target: Node2D
# 0:neutral  1:combat
var combat_state: bool
# 0:static  1:patrolling
var is_patroling: bool
var is_patroling: bool	
var is_static: bool
var is_dead: bool

var noticed_players: Array[Node2D]

var reanimation_time: float
var death_timer: Timer
var stop_time: float
var stop_timer: Timer

var did_collide : bool

func _ready():
	combat_state = false
	combat_target = null
	
	hurtbox = get_node("SkeletonHurtbox")
	los_area = get_node("SkeletonLoS")
	los_area.body_entered.connect(detect)
	los_area.body_exited.connect(deaggro)
	
	read_enemy_data("generic_enemy_parameters")
	#set death clock
	death_timer = Timer.new()
	death_timer.wait_time = reanimation_time
	death_timer.timeout.connect(reanimate)
	add_child(death_timer)
	
	#set stop clock
	stop_timer = Timer.new()
	stop_timer.wait_time = stop_time
	stop_timer.timeout.connect(stop_timer.stop)
	add_child(stop_timer)
	
	
	#establish if enemy will patrol or stay put until player is encountered
	if (patrol.size() > 0):
		is_static = false
		is_patroling = true
		patrol_index = 1
		
		#automatically set first patrol point as enemys original position
		var origin = Node2D.new()
		origin.position = position
		patrol.push_front(origin)
	else: 
		is_patroling = false
		is_static = true

func _physics_process(delta : float):
	if(not is_on_floor()):
		velocity.y += get_gravity().y * delta
		
	if(not sprite.flip_h and velocity.x < 0):
		turnaround()
	elif(sprite.flip_h and velocity.x > 0):
		turnaround()
	if is_dead:
		move_and_slide()
		return
	
	if (patrol.size() == 0 or !stop_timer.is_stopped()) and !combat_state:
		velocity.x = 0
		sprite.set_animation("idle")
		if(not sprite.is_playing()):
			sprite.play()

	elif get_position_delta().x != 0 and !combat_state:
		sprite.set_animation("walk")
		
	move_and_slide()

	if is_patroling:
		var next = float(patrol[patrol_index].global_position.x)

		#reorient sprite and hitbox if necessary
		if ((patrol[patrol_index].global_position.x - global_position.x) < 0 and !sprite.flip_h) or ((patrol[patrol_index].global_position.x - global_position.x) > 0 and sprite.flip_h):
			await turnaround()
		if(next < global_position.x):
			velocity.x = move_toward(velocity.x, -walk_speed, (1000 * delta) / 16)
		else:
			velocity.x = move_toward(velocity.x, walk_speed, (1000 * delta) / 16)
		 
		if ceil(position.x + get_position_delta().x) == next:
			velocity.x = 0
			patrol_index = (patrol_index + 1) % patrol.size()
			#wait ? frames
			stop_timer.start()
		 	
	elif combat_state:
		combat_behavior()

	return

func reanimate():
	death_timer.stop()
	#play reanimation animation
	sprite.set_animation("reanimation")
	await sprite.animation_finished
	#reset to default
	is_dead = false
	los_area.monitoring = true
	hurtbox.disabled = false
	

func hit():
	#effectively forces enemy to freeze
	is_dead = true
	los_area.monitoring = false
	hurtbox.set_deferred("disabled", true)
	
	sprite.set_animation("death")
	death_timer.start()
	
func detect(target : Node2D ):
	if target is PlayerMovement:
		combat_target = target
		combat_state = true
		is_patroling = false
		noticed_players.append(target)
		return true
	return false
	
func deaggro(target : Node2D ):
	if (is_instance_valid(target) and target in noticed_players):
		noticed_players.erase(target)
		if(noticed_players.size() > 0):
			combat_target = noticed_players[0]
			
	if(sprite.is_playing() and sprite.animation != "walk"):
		await sprite.animation_finished
		
	if(noticed_players.size() == 0):
		if patrol.size() > 0:
			combat_target = null
			combat_state = false
			is_patroling = true
		
			#reorient sprite and hitbox if necessary
			if ((patrol[patrol_index].global_position.x - global_position.x) < 0 and !sprite.flip_h) or ((patrol[patrol_index].global_position.x - global_position.x) > 0 and sprite.flip_h):
				await turnaround()
				
		else:
			combat_target = null
			combat_state = false
			sprite.set_animation("idle")
	
func read_enemy_data(sectionName):
	var config = ConfigFile.new()
	
	# Attempt to read enemy settings from an external file
	var error = config.load("res://settings.cfg")
	# Assert that the data was read
	assert(error == OK, "Failed to read enemy settings from settings.cfg")
	#read values from settings.cfg
	walk_speed = config.get_value(sectionName, "walk_speed", walk_speed)
	los_cone_deg = config.get_value(sectionName, "los_cone_deg", los_cone_deg)
	los_distance = config.get_value(sectionName, "los_distance", los_distance)
	reanimation_time = config.get_value(sectionName, "reanimation_time", reanimation_time)
	stop_time = config.get_value(sectionName, "stop_time", stop_time)

func set_los_cone():
	var cone = CollisionPolygon2D.new() 
	cone.position = los_area.position
	
	var origin : Vector2 = Vector2(self.los_area.position.x, self.los_area.position.y)
	var y_offset : int = int(tan(los_cone_deg * (PI/180)) * los_distance)
	cone.polygon= PackedVector2Array([origin, Vector2(origin.x + los_distance, origin.y + y_offset), 
	Vector2(origin.x + los_distance, origin.y -y_offset)])
	
	los_area.add_child(cone)

@abstract 
func attack(target : Node2D)

@abstract
func turnaround()

@abstract
func combat_behavior()	
