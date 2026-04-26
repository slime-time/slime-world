extends RigidBody2D

func entityEntered(_trigger: Node2D):
	# Ensure the arrow only hits the player once
	if not is_queued_for_deletion():
		# After hitting anything, delete the arrow.
		queue_free()
		for entity in get_colliding_bodies():
			if(entity is PlayerMovement):
				entity.hit()
			

func _ready():
	set_freeze_enabled(true)
	set_contact_monitor(true)
	set_freeze_mode(RigidBody2D.FreezeMode.FREEZE_MODE_KINEMATIC)
	set_max_contacts_reported(70)
	set_collision_layer(0)
	set_lock_rotation_enabled(true)
	body_entered.connect(entityEntered)
