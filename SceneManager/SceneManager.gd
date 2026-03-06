extends Node

# True only when the player is in the pause menu, not during cutscenes or other situations
var is_paused = false

# True only when the player could pause the game
var can_pause = true

# When false, _physics_process and _process will do nothing
var physics_applies = true

# Reset the scene
func resetScene():
	print_debug("resetting scene in theory")
	var tree = get_tree()
	tree.call_deferred("reload_current_scene")
	
# Pause the game, and stop the player from moving. The player can unpause from this position
func pauseGame():
	# ToDo: show settings / pause menu UI
	is_paused = true
	physics_applies = false
	InputManager.haltPlayerMovement()
	
func unpauseGame():
	# ToDo: hide settings / pause menu UI
	is_paused = false
	InputManager.resumePlayerMovement()
	physics_applies = true
	
