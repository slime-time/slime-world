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

# Hitboxes used for checking if this slime can merge
var merge_confirm

# Hitbox used for checking if this slime can split
var split_confirm

# True only when the signal to tranform into Penny has already been sent, as to avoid sending a second
# From this slime
var to_transform = false

# Returns a boolean value, true iff the slime can become Penny (i.e. is size 8 and not blue slime)
func canBecomePenny():
	return false

func spikeHit():
	if(size > 1):
		split()
	else:
		die()

# Turn into two slimes
func split(child_slime_type: Slime.Type = slime_type):
	var split_blockers = split_confirm.get_overlapping_bodies()
	if(len(split_blockers) == 1 and split_blockers[0] == self):
		var child_size = floor(size / 2)
		size = ceili(size / 2.0)
		position.x -= 8
		has_split.emit(position + Vector2(16, 0), velocity, child_size, child_slime_type)
		getMovementAbility()
		updateHitbox()
		updateSprite()
	else:
		takeDamage(1)
	
# Returns true iff this slime can change size to become a "merged_size" slime, false otherwise.
func testMerge(merged_size: int, merging_with: Node) -> bool:
	var relevant_hitbox = merge_confirm.get_node("Size" + str(merged_size) + "Confirm")
	for overlap in relevant_hitbox.get_overlapping_bodies():
		if(overlap != self and overlap != merging_with and not overlap.is_queued_for_deletion()):
			return false
	return true

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

# Attempt to change from slime form to human form
func becomePenny():
	if canBecomePenny() and not to_transform:
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
	merge_confirm = get_node("MergeConfirm")
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

# Update the sprite representing this slime after it changes size
func updateSprite():
	var my_sprite = get_node("Sprite2D")
	my_sprite.texture = load("res://assets/" + sprite_name + "/" + sprite_name + "-" + str(size) + ".png")

	# Temporary fix until all sprites have animations
	if(size == 8 && slime_type == Type.GREEN_SLIME):
		my_sprite.hframes = 4
	else:
		my_sprite.hframes = 1
