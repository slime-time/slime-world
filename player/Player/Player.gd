extends Node2D

# False whenever Penny is in slime form
var am_penny = true

# Reference to Penny
var penny;

var green_slime_template = preload("res://player/Slime/GreenSlime/GreenSlime.tscn")

# Reference to all slimes that exist
var slimes = []

func _ready():
	penny = get_node("Penny")
	InputManager.penny_became_slime.connect(makePennyIntoSlime)
	
# Make a green slime of the specified size and location
func makeGreenSlime(x, y, size):
	var latest_slime = green_slime_template.instantiate()
	latest_slime.position.x = x
	latest_slime.position.y = y
	latest_slime.size = size
	InputManager.slime_became_penny.connect(latest_slime.becomePenny)
	latest_slime.became_penny.connect(makeSlimeIntoPenny)
	slimes.append(latest_slime)
	add_child(latest_slime)
	
# Make Penny invisible and take away her physics, then add a max size slime (size 8) in her place
func makePennyIntoSlime():
	var old_velocity = penny.velocity;
	penny.set_visible(false)
	makeGreenSlime(penny.position.x, penny.position.y, 8)
	penny.set_process_mode(Node.PROCESS_MODE_DISABLED)
	slimes[0].velocity = old_velocity
# If a large slime turned into Penny, add back Penny
func makeSlimeIntoPenny():
	# If a slime is turning into Penny, it must be the only slime
	var old_velocity = slimes[0].velocity
	penny.position = slimes[0].position
	slimes[0].queue_free()
	slimes.pop_front() 
	penny.set_process_mode(Node.PROCESS_MODE_INHERIT)
	penny.set_visible(true)
	penny.velocity = old_velocity
