extends Node2D

# False whenever Penny is in slime form
var am_penny

# Reference to Penny
var penny;

# Preload the basic green slime, modifications to the template can be made at runtime
var green_slime_template = preload("res://player/Slime/GreenSlime/GreenSlime.tscn")


# Reference to all slimes that exist
var slimes = []

func _ready():
	InputManager.is_human = true
	am_penny = true
	penny = get_node("Penny")
	InputManager.penny_became_slime.connect(makePennyIntoSlime)
	
func makeSlime(starting_location: Vector2, starting_velocity: Vector2, size: int, type: Slime.Type):
	match type:
		Slime.Type.GREEN_SLIME:
			makeGreenSlime(starting_location.x, starting_location.y, size, starting_velocity)

# Make a green slime of the specified size and location
func makeGreenSlime(x, y, size, starting_velocity: Vector2 = Vector2.ZERO):
	var latest_slime = green_slime_template.instantiate()
	latest_slime.size = size
	latest_slime.position.x = x
	latest_slime.position.y = y

	
	latest_slime.velocity = starting_velocity
	# When the InputManager finds that the player has requested tranformation from slime to human
	# then send "slime_became_penny" signal to all slimes - if the slime can turn into human it will send a
	# "became_penny" signal to the Player object - only one slime can ever meet the conditions for turning into human,
	# so there is no concern of a repeat signal
	InputManager.slime_became_penny.connect(latest_slime.becomePenny)
	latest_slime.became_penny.connect(makeSlimeIntoPenny)
	latest_slime.has_split.connect(makeSlime)
	
	slimes.append(latest_slime)
	self.call_deferred("add_child", latest_slime, false, InternalMode.INTERNAL_MODE_BACK)
	
# Make Penny invisible and take away her physics, then add a max size slime (size 8) in her place
func makePennyIntoSlime():
	var old_velocity = penny.velocity;
	penny.set_visible(false)
	# Make a slime at Penny's position
	makeGreenSlime(penny.position.x, penny.position.y, 8)
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
