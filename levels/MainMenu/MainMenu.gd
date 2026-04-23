extends CanvasLayer

@onready var new_game_button = %NewGame
@onready var load_game_button = %LoadGame
@onready var back_button = %BackButton
@onready var level_select = %LevelSelect
@onready var save_slot_select = %SaveSlotSelect
@onready var player_name_edit = %PlayerNameEdit
@onready var continue_button = %ContinueButton

enum MainMenuState {
	MAIN_MENU_HOME,
	NAME_INPUT,
	LEVEL_SELECT,
	SAVE_SLOT_SELECT
}

var mainMenuState: MainMenuState

func _switchToMenuState(newState: MainMenuState):
	new_game_button.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	load_game_button.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	
	# Back button is visible in all states except the main menu home state, where it is not needed.
	back_button.visible = (newState != MainMenuState.MAIN_MENU_HOME) 
	
	level_select.visible = (newState == MainMenuState.LEVEL_SELECT)
	
	save_slot_select.visible = (newState == MainMenuState.SAVE_SLOT_SELECT)

	player_name_edit.visible = (newState == MainMenuState.NAME_INPUT)
	continue_button.visible = (newState == MainMenuState.NAME_INPUT)
	
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
	# Now we actually create the save file and set the player name in the save data
	GameManager.current_state.loadSaveSlot(-1) # This will create a new save slot and load it into the current game state, which is what we want
	_switchToMenuState(MainMenuState.LEVEL_SELECT)
