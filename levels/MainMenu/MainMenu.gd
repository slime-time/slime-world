extends CanvasLayer

@onready var newGameButton = %NewGame
@onready var loadGameButton = %LoadGame
@onready var backButton = %BackButton
@onready var LevelSelect = %LevelSelect
@onready var SaveSlotSelect = %SaveSlotSelect

enum MainMenuState {
	MAIN_MENU_HOME,
	NAME_INPUT,
	LEVEL_SELECT,
	SAVE_SLOT_SELECT
}

var mainMenuState: MainMenuState

func _switchToMenuState(newState: MainMenuState):
	newGameButton.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	loadGameButton.visible = (newState == MainMenuState.MAIN_MENU_HOME)
	backButton.visible = (newState != MainMenuState.MAIN_MENU_HOME)
	LevelSelect.visible = (newState == MainMenuState.LEVEL_SELECT)
	SaveSlotSelect.visible = (newState == MainMenuState.SAVE_SLOT_SELECT)
	
	mainMenuState = newState

func _ready() -> void:
	_switchToMenuState(MainMenuState.MAIN_MENU_HOME)

func _onNewGamePressed() -> void:
	_switchToMenuState(MainMenuState.LEVEL_SELECT)

func _onLoadGamePressed() -> void:
	_switchToMenuState(MainMenuState.SAVE_SLOT_SELECT)

## Always returns to main menu. But should be updateable if need be.
func _onBackButtonPressed() -> void:
	_switchToMenuState(MainMenuState.MAIN_MENU_HOME)