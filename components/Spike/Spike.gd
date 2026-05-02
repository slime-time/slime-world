extends RigidBody2D
class_name Spike

const SPIKE_COLLISION_LAYER = 18

func entityEntered(_trigger: Node2D):
	# Ensure the spike only hits the ground once
	if not is_queued_for_deletion():
		var any_non_ice_slime = false

		for entity in get_colliding_bodies():
			if (entity is IceSlime): continue
			any_non_ice_slime = true
			if (entity is PlayerMovement):
				entity.hit()

		if any_non_ice_slime:
			# After hitting anything, delete the spike.
			queue_free()

func _ready():
	set_freeze_enabled(true)
	set_contact_monitor(true)
	set_freeze_mode(RigidBody2D.FreezeMode.FREEZE_MODE_KINEMATIC)
	set_max_contacts_reported(70)
	set_collision_layer(0)
	set_collision_layer_value(SPIKE_COLLISION_LAYER, true)
	set_lock_rotation_enabled(true)
	body_entered.connect(entityEntered)

# We don't care how many times the spike is told to fall because after being called once,
# further calls to fall do nothing
func fall():
	call_deferred("set_freeze_enabled", false)
