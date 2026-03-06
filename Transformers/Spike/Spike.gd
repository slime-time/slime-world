extends RigidBody2D

func _ready():
	set_freeze_enabled(true)
	set_contact_monitor(true)
	set_lock_rotation_enabled(true)
	
# We don't care how many times the spike is told to fall because after being called once,
# further calls to fall do nothing
func fall():
	call_deferred("set_freeze_enabled", false)
