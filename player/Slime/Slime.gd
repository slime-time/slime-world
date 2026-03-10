@abstract class_name Slime 
extends "res://player/PlayerMovement/PlayerMovement.gd"

# Store the y position of the circular body for the round/blob slime of the corresponding size
const BODY_OFFSETS = [0, 0, 0, 0, 3, 0, 0, 0, 0]

# The name used to load the sprites for this slime type
var sprite_name

# The name used to load the hitboxes for this slime type
var hitbox_name

# The name used to load the movement data for this slime
var movement_name
enum Type {
	GREEN_SLIME = 1
}
# What type of slime is this slime?
var slime_type

# Signal sent when the transform button is pressed and we are a slime that can become Penny
signal became_penny

# Signal sent when this slime splits into 2 different slimes
signal has_split

# Size of this slime in 1/8ths of the largest slime
var size

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
func split():
	var child_size = floor(size / 2)
	size = ceil(size / 2)
	position -= Vector2(10, 0)
	has_split.emit(position + Vector2(20, 0), velocity, child_size, slime_type)
	getMovementAbility()
	updateHitbox()
	updateSprite()
	


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

func _ready():
	super()
	read_movement_data(movement_name)
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
	if(size == 8):
		my_sprite.hframes = 4
	else:
		my_sprite.hframes = 1
