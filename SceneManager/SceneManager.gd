extends Node

# True only when the player is in the pause menu, not during cutscenes or other situations
var is_paused = false

func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)

	get_tree().root.child_entered_tree.connect(_onRootChildAdded)
	call_deferred("_onSceneLoaded", get_tree().current_scene)

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

const PAUSE_MENU = preload("res://components/PauseMenu/PauseMenu.tscn")

## Used to show / hide pause menu
signal pause_state_changed

# Pause the game, and stop the player from moving. The player can unpause from this position
func pauseGame():
	pause_state_changed.emit(true)
	get_tree().paused = true
	is_paused = true
	AudioManager.call_deferred("set_current_track", "sgsw_pause_theme.wav")
	TransitionManager.setCRTFilter(true)

func unpauseGame():
	pause_state_changed.emit(false)
	get_tree().paused = false
	is_paused = false
	AudioManager.call_deferred("set_current_track", "sgsw_theme1.wav")
	TransitionManager.setCRTFilter(false)

# Runs when a direct child of the root node is added so we can detect when a new scene is loaded
func _onRootChildAdded(node : Node2D) -> void:
	_onSceneLoaded.call_deferred(node)

# Runs on the next update after a direct child node of the root is added (potentially a new scene loaded)
func _onSceneLoaded(node : Node2D) -> void:
	# Don't do anything if the node that was added isn't the current scene
	if node != get_tree().get_current_scene():
		return

	# If the scene isn't ready yet, wait for it to be ready
	if node.is_node_ready():
		_onSceneReady()
	else:
		node.ready.connect(_onSceneReady)

# Runs when a newly loaded scene becomes ready
func _onSceneReady() -> void:
	
	# We're on the main menu -- there is no pause menu
	if (GameManager.current_state.cur_level == 0):
		return

	# Otherwise add pause menu to scence
	var pause_menu = PAUSE_MENU.instantiate()
	get_tree().current_scene.add_child(pause_menu)
	pause_menu.layer = 1000000007
