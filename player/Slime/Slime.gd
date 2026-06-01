@abstract class_name Slime
extends PlayerMovement

# Store the y position of the circular body for the round/blob slime of the corresponding size
const BODY_OFFSETS = [0, 5, 4, 3, 2, 2, 0, 0, 0]

# The name used to load the sprites for this slime vtype
var sprite_name: String

# The name used to load the hitboxes for this slime type
var hitbox_name: String

# The name used to load the movement data for this slime
var movement_name: String

var base_run_max_velocity
var base_run_acceleration
var base_run_deceleration
var base_jump_velocity
var base_climb_max_speed # Maximum speed this slime can climb up objects
var base_mass

enum Type {
	UNSET = 0,
	GREEN_SLIME = 1,
	ICE_SLIME = 2,
	TAR_SLIME = 3,
	ENERGIZED_SLIME = 4
}
# What type of slime is this slime?
var slime_type: Type

# Signal sent when the transform button is pressed and we are a slime that can become Penny
signal became_penny

# Signal sent when this slime splits into 2 different slimes
signal has_split

# Signal sent when slimes should merge together
signal slimes_merged
# Signal sent when this slime is replaced
signal slime_type_changed

# Size of this slime in 1/8ths of the largest slime
var size

# Hitbox used for checking if this slime can split
var split_confirm

# True only when the signal to tranform into Penny has already been sent, as to avoid sending a second
# From this slime
var to_transform = false

var in_gas_volume: bool = false

# Returns a boolean value, true iff the slime can become Penny (i.e. is size 8 and not blue slime)
func canBecomePenny():
	return false

func hit():
	if(size > 1):
		split(slime_type, true)
	else:
		die()

func getActualFluidVelocity(fluid_velocity_low: Vector2, fluid_velocity_high: Vector2, min_slime_size: int) -> Vector2:
	if size < min_slime_size:
		return fluid_velocity_high * run_max_velocity

	return fluid_velocity_low * run_max_velocity

# Turn into two slimes
func split(child_slime_type: Slime.Type = slime_type, avoid_stacking: bool = false):
	AudioManager.call_deferred("play_sfx", "slime_footstep", 1, 1.0, -10.5)
	if(size >= 2):
		var child_size = floor(size / 2)
		size = ceili(size / 2.0)
		var random_x = randf_range(4.0, 6.0)
		move_and_collide(Vector2(-random_x, 0))
		
		
		var child_pos = position + Vector2(random_x, -randf_range(3, 5))
		var child_vel = velocity

		position += Vector2(0, -randf_range(3, 5))

		if avoid_stacking:
			position.x += 8
			child_pos.x -= 8

		velocity += Vector2(-50, 0)
		child_vel += Vector2(50, 0)

		has_split.emit(child_pos, child_vel, child_size, child_slime_type)
		getMovementAbility()
		updateHitbox()
		updateSprite()
	else:
		takeDamage(1)


# I was merged with another slime, increase my size
func merge(merged_size: int):
	size = merged_size
	getMovementAbility()
	updateHitbox()
	updateSprite()

func onFluidHit(fluid_type: FluidFlow.Type) -> void:
	match fluid_type:
		FluidFlow.Type.WATER:
			if slime_type == Type.GREEN_SLIME: return
			slime_type_changed.emit(self, Type.GREEN_SLIME)
		FluidFlow.Type.ICE_WATER:
			if slime_type == Type.ICE_SLIME: return
			slime_type_changed.emit(self, Type.ICE_SLIME)
		FluidFlow.Type.TAR:
			if slime_type == Type.TAR_SLIME: return
			slime_type_changed.emit(self, Type.TAR_SLIME)
		FluidFlow.Type.ENERGIZED:
			if slime_type == Type.ENERGIZED_SLIME: return
			slime_type_changed.emit(self, Type.ENERGIZED_SLIME)

# Attempt to change from slime form to human form
func becomePenny():
	if canBecomePenny() and not to_transform and not in_gas_volume:
		# Disable this node, it will be deleted later but first its data must be used to setup human form properties
		set_process_mode(Node.PROCESS_MODE_DISABLED)

		became_penny.emit()
		to_transform = true
		# Tell InputManager that the transformation attempt was successful, so our next transformation will be from
		# human to slime
		InputManager.is_human = true
	else:
		slimes_merged.emit(self.get_instance_id())

func _ready():
	super()
	read_movement_data(movement_name)
	base_run_max_velocity = run_max_velocity
	base_run_acceleration = run_acceleration
	base_run_deceleration = run_deceleration
	base_jump_velocity = jump_velocity
	base_climb_max_speed = climb_max_speed
	base_mass = mass
	split_confirm = get_node("SplitConfirm")
	updateHitbox()
	updateSprite()
	getMovementAbility()

# Should be implemented differently for each slime - gives movement_speed and jump_velocity
# As a function of the size of the slime
@abstract func getMovementAbility()

# Should be overriden for ice slime and other slimes with unusual shapes
func updateHitbox():
	var my_base = get_node("SlimeBase")
	var my_body = get_node("SlimeBody")

	# Load the resources asynchronously so that some of the loading can be done
	# In the background while we are waiting until we are allowed to change the shape of a hitbox
	ResourceLoader.load_threaded_request(
		"res://player/Slime/" + hitbox_name + "/Hitboxes/" + hitbox_name + "-" +
		str(size) + "/" + hitbox_name + "-Base-" + str(size) + ".tres"
	)
	ResourceLoader.load_threaded_request(
		"res://player/Slime/" + hitbox_name + "/Hitboxes/" + hitbox_name + "-" +
		str(size) + "/" + hitbox_name + "-Body-" + str(size) + ".tres"
	)

	(func():
		my_body.shape = ResourceLoader.load_threaded_get("res://player/Slime/" + hitbox_name + "/Hitboxes/"
		+ hitbox_name + "-" + str(size) + "/" + hitbox_name + "-Body-" + str(size) + ".tres")
		my_base.shape = ResourceLoader.load_threaded_get("res://player/Slime/" + hitbox_name + "/Hitboxes/"
		+ hitbox_name + "-" + str(size) + "/" + hitbox_name + "-Base-" + str(size) + ".tres")
	).call_deferred()

	my_body.position.y = BODY_OFFSETS[size]

	recomputeNetFluidVelocity()

# Update the sprite representing this slime after it changes size
func updateSprite():
	var my_sprite = get_node("Sprite2D")
	my_sprite.texture = load("res://assets/" + sprite_name + "/" + sprite_name + "-" + str(size) + ".png")

	# Temporary fix until all sprites have animations
	if(size == 8 && slime_type == Type.GREEN_SLIME):
		my_sprite.hframes = 4
	else:
		my_sprite.hframes = 1
