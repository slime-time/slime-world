extends Node

# True only when the player is in the pause menu, not during cutscenes or other situations
var is_paused = false

func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
# True only when the player could pause the game
var can_pause = true

# When false, _physics_process and _process will do nothing
var physics_applies = true

# Frame number of the last time resetScene was called, to avoid reloading multiple times due to
# multiple characters dying at the same time
var last_death
# Reset the scene
func resetScene():
	var tree = get_tree()
	if(tree.get_frame() != last_death): # and GameManager.current_state.cur_level != 0):
		last_death = tree.get_frame()
		TarManager.resetTar()
		tree.call_deferred("reload_current_scene")
	
# Pause the game, and stop the player from moving. The player can unpause from this position
func pauseGame():
	# ToDo: show settings / pause menu UI
	get_tree().paused = true
	is_paused = true
	
func unpauseGame():
	# ToDo: hide settings / pause menu UI
	get_tree().paused = false
	is_paused = false
