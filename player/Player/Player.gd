class_name Player
extends Node2D

# False whenever Penny is in slime form
var am_penny

# Reference to Penny
var penny;

# Preload the basic green slime, modifications to the template can be made at runtime
var slime_templates: Dictionary[Slime.Type, Resource] = {
	Slime.Type.GREEN_SLIME: preload("res://player/Slime/GreenSlime/GreenSlime.tscn"),
	Slime.Type.ICE_SLIME: preload("res://player/Slime/IceSlime/IceSlime.tscn"),
}

# Reference to all slimes that exist
var slimes = []

# Merge slimes iff the slime requesting the merge is the slime at slimes[0], to prevent multiple
# Merge requests happening at the same time
func mergeSlimes(requester_id: int):
	if(len(slimes) > 0 and slimes[0].get_instance_id() == requester_id):
		print_debug("merge logic here")

func _ready():
	InputManager.is_human = true
	am_penny = true
	penny = get_node("Penny")
	InputManager.penny_became_slime.connect(makePennyIntoSlime)

func changeSlimeType(slime: Slime, new_type: Slime.Type):
	slimes.erase(slime)
	slime.queue_free()
	makeSlime(slime.position, slime.velocity, slime.size, new_type)

func makeSlime(starting_location: Vector2, starting_velocity: Vector2, size: int, type: Slime.Type):
	var node = slime_templates[type].instantiate()
	node.position = starting_location
	node.velocity = starting_velocity
	node.size = size

	InputManager.slime_became_penny.connect(node.becomePenny)
	node.became_penny.connect(makeSlimeIntoPenny)
	node.has_split.connect(makeSlime)
	node.slime_type_changed.connect(changeSlimeType)

	slimes.append(node)
	self.call_deferred("add_child", node, false, InternalMode.INTERNAL_MODE_BACK)

# Make Penny invisible and take away her physics, then add a max size slime (size 8) in her place
func makePennyIntoSlime():
	var old_velocity = penny.velocity;
	penny.set_visible(false)
	# Make a slime at Penny's position
	makeSlime(penny.position, Vector2.ZERO, 8, Slime.Type.GREEN_SLIME)
	penny.set_process_mode(Node.PROCESS_MODE_DISABLED)
	slimes[0].velocity = old_velocity


# If a large slime turned into Penny, add back Penny
func makeSlimeIntoPenny():
	# If a slime is turning into Penny, it must be the only slime: slimes[0]

	# Give Penny the location and velocity of the slime blob she transformed from
	penny.position = slimes[0].position
	penny.velocity = slimes[0].velocity

	# Free the slime
	slimes[0].queue_free()
	slimes.pop_front()

	# Wake up Penny
	penny.set_process_mode(Node.PROCESS_MODE_INHERIT)
	penny.set_visible(true)
