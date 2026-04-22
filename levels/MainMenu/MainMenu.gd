extends CanvasLayer

@onready var newGameButton = %NewGame
@onready var loadGameButton = %LoadGame
@onready var backButton = %BackButton
@onready var LevelSelect = %LevelSelect
@onready var SaveSlotSelect = %SaveSlotSelect

func _onNewGamePressed() -> void:
	newGameButton.visible = false
	loadGameButton.visible = false

	LevelSelect.visible = true
	backButton.visible = true


func _onLoadGamePressed() -> void:
	newGameButton.visible = false
	loadGameButton.visible = false

	SaveSlotSelect.visible = true
	backButton.visible = true

## Resets the menu to its default state. Silly? Yes. Works? Also yes.
func _onBackButtonPressed() -> void:
	newGameButton.visible = true
	loadGameButton.visible = true

	backButton.visible = false
	LevelSelect.visible = false
	SaveSlotSelect.visible = false
