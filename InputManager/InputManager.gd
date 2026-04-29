extends Control

# Sent when Penny goes from human form to slime form
signal penny_became_slime

# Sent when Penny goes from slime form to human form
signal slime_became_penny

# True if Penny is currently in human form
var is_human = true

# The input manager should never stop listening for events
func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)

func get_is_human():
	return is_human

func _input(event):
	# If the player has just started pressing down on the pause button then:
	if event.is_action_pressed("quick_pause"):
		# If the game can be paused, pause the game and wait until the button is released to listen for
		# a signal to unpause
		if GameManager.current_state.cur_level != 0 and (not get_tree().is_paused()):
			SceneManager.pauseGame()
		# If the game can be unpaused, unpause the game and wait until the button is released to listen for
		# a signal to pause
		elif get_tree().is_paused():
			SceneManager.unpauseGame()
			
	# If the player didn't pause and is pressing a transform button, then send the appropriate signal
	if event.is_action_pressed("transform") and (not get_tree().is_paused()) : 
		if(is_human):
			penny_became_slime.emit()
			# If this is successful, Player.gd will set is_human to false
		else:
			slime_became_penny.emit()
			# If this is successful, Slime.gd will set is_human to true
	
	if event.is_action_pressed("reset") and (not get_tree().is_paused()):
		SceneManager.resetScene()
