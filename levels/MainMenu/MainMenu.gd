extends CanvasLayer

@onready var new_game_button = %NewGame
@onready var load_game_button = %LoadGame
@onready var back_button = %BackButton
@onready var level_select = %LevelSelect
@onready var save_slot_select = %SaveSlotSelect
@onready var player_name_edit = %PlayerNameEdit
@onready var continue_button = %ContinueButton
@onready var title_label = %TitleLabel

enum MainMenuState {
	MAIN_MENU_HOME,
	NAME_INPUT,
	LEVEL_SELECT,
	SAVE_SLOT_SELECT
}

var mainMenuState: MainMenuState

var player_name: String = ""

func _switchToMenuState(newState: MainMenuState):
	new_game_button.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	load_game_button.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	
	# Back button is visible in all states except the main menu home state, where it is not needed.
	back_button.visible = (newState != MainMenuState.MAIN_MENU_HOME) 
	
	level_select.visible = (newState == MainMenuState.LEVEL_SELECT)
	if (level_select.visible): 
		level_select.reload()
	
	save_slot_select.visible = (newState == MainMenuState.SAVE_SLOT_SELECT)
	if (save_slot_select.visible): 
		save_slot_select.reload()

	player_name_edit.visible = (newState == MainMenuState.NAME_INPUT)
	continue_button.visible = (newState == MainMenuState.NAME_INPUT)

	# Always reset local player name when changing states
	player_name = ""
	if (newState == MainMenuState.NAME_INPUT):
		continue_button.disabled = true # Disable the continue button until the player has entered a name
	
	# If on level select screen, will change title to include player name
	if (newState == MainMenuState.LEVEL_SELECT):
		if (GameManager.current_state.player_name.length() <= 10):
			title_label.text = "Slime " + GameManager.current_state.player_name + ", Slime World"
		else:
			title_label.text = "Slime " + GameManager.current_state.player_name + ",\nSlime World"
	else:
		title_label.text = "Slime Girl, Slime World"

	mainMenuState = newState

func _ready() -> void:
	if (GameManager.current_state.save_slot == -1): # If we haven't chosen a save slot yet, open main menu home.
		_switchToMenuState(MainMenuState.MAIN_MENU_HOME)
	else: # Otherwise, go straight to level select
		_switchToMenuState(MainMenuState.LEVEL_SELECT)

func _onNewGamePressed() -> void:
	_switchToMenuState(MainMenuState.NAME_INPUT)

func _onLoadGamePressed() -> void:
	_switchToMenuState(MainMenuState.SAVE_SLOT_SELECT)

## Always returns to main menu. But should be updateable if need be.
func _onBackButtonPressed() -> void:
	_switchToMenuState(MainMenuState.MAIN_MENU_HOME)

func _onContinueButtonPressed() -> void:
	if (player_name == ""):
		# For now, we'll just return without doing anything.
		return

	# Now we actually create the save file and set the player name in the save data
	GameManager.current_state = GameState.new() # Reset GameState to default values
	GameManager.current_state.loadSaveSlot(-1)

	# Debug!!!
	print("Highest_level_unlocked " + str(GameManager.current_state.highest_level_unlocked))

	GameManager.current_state.player_name = player_name # Set the player name in the current game state
	GameManager.current_state.saveKeys(["player_name"]) # Save to file
	_switchToMenuState(MainMenuState.LEVEL_SELECT)

func _onPlayerNameEntered(new_text: String) -> void:
	player_name = new_text.strip_edges() # Remove leading and trailing whitespace from the player name
	
	# Don't accept names that are too long
	if (player_name.length() > 23):
		player_name = ""
	
	# Enable connected button if player name is not empty
	continue_button.disabled = (player_name == "")
