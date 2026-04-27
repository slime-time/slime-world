extends RigidBody2D

var target : Vector2
var speed

func entityEntered(_trigger: Node2D):
	# Ensure the arrow only hits the player once
	if not is_queued_for_deletion():
		# After hitting anything, delete the arrow.
		queue_free()
		for entity in get_colliding_bodies():
			if(entity is PlayerMovement):
				entity.hit()
			
	

func _ready():
	set_gravity_scale(0.0)
	set_contact_monitor(true)
	set_max_contacts_reported(70)
	set_collision_layer(0)
	set_lock_rotation_enabled(true)
	body_entered.connect(entityEntered)

func _physics_process(delta: float):
	var mulitplier
	if target.x > global_position.x:
		mulitplier = 1
	else:
		mulitplier = -1
	linear_velocity = Vector2(speed * mulitplier, 0)
