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

# The maximal distance that slimes can merge together
var merge_distance = 30.0

# Store the frame the last merge was requested on, to avoid requesting a merge multiple times on one frame
var merge_frame = -1
# Merge slimes iff the slime requesting the merge is the slime at slimes[0], to prevent multiple
# Merge requests happening at the same time
func mergeSlimes(requester_id: int):
	
	if(len(slimes) > 0 and merge_frame != get_tree().get_frame() and slimes[0].get_instance_id() == requester_id):
		merge_frame = get_tree().get_frame()
		var local_slimes = slimes.duplicate()
		local_slimes.sort_custom(func(a, b): 
			if(a.size == b.size):
				return a.position.x < b.position.x
			return a.size > b.size
		)
		# global array indices of the sorted local array
		var local_to_global = []
		# Store the index (in local) of the slime this slime is going to merge with
		var my_merge = []
		# Store the size this slime will be after all merges
		var sizes = []
		# Avoid reporting collisions between slimes since merge should only be stopped by collision with
		# non-slime objects
		for setup in local_slimes:
			my_merge.append(-1)
			sizes.append(setup.size)
			for exemption_index in range(len(slimes)):
				if(setup.get_instance_id() == slimes[exemption_index].get_instance_id()):
					local_to_global.append(exemption_index)
				setup.add_collision_exception_with(slimes[exemption_index])
				
		for start_slime in range(len(local_slimes)):
			for target_slime in range(start_slime + 1, len(local_slimes)):
				# Merge only if the slimes are the same type, not set to merge with any other slime, and
				# within a set radius of each other, and there are no solid objects between them
				if(my_merge[target_slime] == -1 and my_merge[start_slime] == -1 and
				local_slimes[start_slime].slime_type == local_slimes[target_slime].slime_type and 
				local_slimes[start_slime].position.distance_to(local_slimes[target_slime].position) < merge_distance):
					
					var obstacles: KinematicCollision2D = local_slimes[target_slime].move_and_collide(local_slimes[start_slime].position - local_slimes[target_slime].position, true)
					
					if obstacles == null or obstacles.get_depth() < local_slimes[start_slime].get_safe_margin():
						# Set the target slime to merge with the starting slime
						my_merge[target_slime] = start_slime
						# Add the target slime's size to the start slime's size
						sizes[start_slime] += local_slimes[target_slime].size
						# Queue the slime I matched with for deletion so that all slimes that are going
						# to be deleted are deleted before merge calls are made
						local_slimes[target_slime].queue_free()
						
		
		# Take away the collision exceptions made for the purpose of testing for separation
		for unsetup in local_slimes:
			for unexemption in local_slimes:
				if local_slimes:
					unsetup.remove_collision_exception_with(unexemption)
	
		# Store the slimes that are not merged into another slime
		var surviving_slimes = []
		for finalizer in range(len(local_slimes)):
			if my_merge[finalizer] == -1:
				surviving_slimes.append(local_slimes[finalizer])
				local_slimes[finalizer].call_deferred("merge", sizes[finalizer])
			
		# After everything else is done, update slimes to only store the slimes that weren't merged away
		(func(): slimes = surviving_slimes).call_deferred()
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
	node.slimes_merged.connect(mergeSlimes)
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
