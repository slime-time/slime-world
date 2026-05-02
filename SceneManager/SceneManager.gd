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
	if get_tree().get_frame() == last_death:
		return

	last_death = tree.get_frame()
	TarManager.resetTar()
	tree.call_deferred("reload_current_scene")

func transitionOutThenResetScene(because_of_death: bool = false):
	if GameManager.current_state.cur_level == 0 or TransitionManager.isClosing():
		return

	TransitionManager.transitionFinished.connect(resetScene, ConnectFlags.CONNECT_ONE_SHOT)
	TransitionManager.startTransitionToBlack(because_of_death)

# Pause the game, and stop the player from moving. The player can unpause from this position
func pauseGame():
	# ToDo: show settings / pause menu UI, update audio manager method call for pause theme
	get_tree().paused = true
	is_paused = true
	AudioManager.call_deferred("set_current_track", "sgsw_pause_theme.wav")

func unpauseGame():
	# ToDo: hide settings / pause menu UI, update audio manager method call for level theme
	get_tree().paused = false
	is_paused = false
	AudioManager.call_deferred("set_current_track", "sgsw_theme1.wav")
