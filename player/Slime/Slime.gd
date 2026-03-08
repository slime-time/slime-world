@abstract class_name Slime 
extends "res://player/PlayerMovement/PlayerMovement.gd"

# Signal sent when the transform button is pressed and we are a slime that can become Penny
signal became_penny

# Size of this slime in 1/8ths of the largest slime
var size

# True only when the signal to tranform into Penny has already been sent, as to avoid sending a second
# From this slime
var to_transform = false

# Returns a boolean value, true iff the slime can become Penny (i.e. is size 8 and not blue slime)
func canBecomePenny():
	return size >= 8

# Turn into two slimes, if possible. To be completed later
func split():
	return false 


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

# Should be implemented differently for each slime - gives movement_speed and jump_velocity
# As a function of the size of the slime
@abstract func getMovementAbility()
