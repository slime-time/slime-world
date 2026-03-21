extends Control

# Sent when Penny goes from human form to slime form
signal penny_became_slime

# Sent when Penny goes from slime form to human form
signal slime_became_penny

# True iff Penny is currently in human form
var is_human = true

# True only when input events should be sent to the player
var player_control = false

# True only when the player has no control but is not in a pause menu.
# Most often triggered on title screen or in cutscene or in dialogue
var special_state = false

# True only when the player has the ability to pause the game by pressing a pause button
# Pause button can be physical and/or implemented with a GUI later
# Player can pause only when not in a cutscene nor pause menu
var can_pause = true

# True only when the player has the ability to unpause the game by pressing a pause button
# Pause button can be physical and/or implemented with a GUI later
# Player can only unpause when in pause menu
var can_unpause = false

# A list of actions that Penny listens to that should be disabled while the game is paused
const PLAYER_ACTIONS = ["move_left", "move_right", "jump", "transform"]

# Temporarily store player input settings while the player cannot move
var player_keybinds = []
var player_deadzones = []

func _input(event):
	# If the player has just started pressing down on the pause button then:
	if event.is_action_pressed("quick_pause"):
		# If the game can be paused, pause the game and wait until the button is released to listen for
		# a signal to unpause
		if can_pause and SceneManager.can_pause:
			SceneManager.pauseGame()
			can_pause = false
		# If the game can be unpaused, unpause the game and wait until the button is released to listen for
		# a signal to pause
		elif can_unpause and SceneManager.is_paused:
			SceneManager.unpauseGame()
			can_unpause = false
			
	# If the player has released the pause button then listen for a pause/unpause signal depending on the situation
	if event.is_action_released("quick_pause"):
		if(SceneManager.is_paused and SceneManager.can_pause):
			can_unpause = true
		elif(SceneManager.can_pause):
			can_pause = true
		
	# If the player didn't pause and is pressing a transform button, then send the appropriate signal
	if event.is_action_pressed("transform") : 
		if(is_human):
			penny_became_slime.emit()
			# Turning to slime always succeeds, so we can just set the is_human flag here
			is_human = false
		else:
			slime_became_penny.emit()
			# If this is successful, Slime.gd will set is_human to true
	
	if event.is_action_pressed("reset"):
		SceneManager.resetScene()

# Stop slime from listening to player input - this can be for many reasons such as cutscenes,
# dialogue, etc, user pausing is just one of the reasons
func haltPlayerMovement():
	# Remove actions after extracting and saving their information to restore the actions later
	for action in PLAYER_ACTIONS:
		# This is very important, keys held before pausing remain held without this, breaking control
		Input.action_release(action)
		
		player_keybinds.append(InputMap.action_get_events(action))
		player_deadzones.append(InputMap.action_get_deadzone(action))
		InputMap.action_erase_events(action)

# Do the inverse of haltPlayerMovement, return control to the player
func resumePlayerMovement():
	# Restore the movement actions one by one
	for action_index in range(player_keybinds.size()):
		for keybind in player_keybinds[action_index]:
			InputMap.action_add_event(PLAYER_ACTIONS[action_index], keybind)
			
	player_keybinds.clear()
	player_deadzones.clear()
