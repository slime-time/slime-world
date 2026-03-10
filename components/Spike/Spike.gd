extends RigidBody2D

func entityEntered(entity: Node2D):
	# Ensure the spike only hits the ground once
	if not is_queued_for_deletion():
		# After hitting anything, delete the spike.
		queue_free()
		
		if(entity is PlayerMovement):
			entity.spikeHit()
			

func _ready():
	set_freeze_enabled(true)
	set_contact_monitor(true)
	set_max_contacts_reported(70)
	set_lock_rotation_enabled(true)
	body_entered.connect(entityEntered)
	
# We don't care how many times the spike is told to fall because after being called once,
# further calls to fall do nothing
func fall():
	call_deferred("set_freeze_enabled", false)
