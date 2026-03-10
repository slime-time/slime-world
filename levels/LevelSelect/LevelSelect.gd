extends Control

const LevelSelectButton = preload("res://levels/LevelSelect/LevelSelectButton.tscn")


func _ready() -> void:
	# Add level buttons
	for level_idx in range(1, GameManager.levels.size()):
		var button = LevelSelectButton.instantiate()
		
		button.setLabel("Level " + str(level_idx))

		# Disable button if level hasn't been unlocked yet
		if (level_idx > GameManager.highest_level_unlocked):
			button.disabled = true;

		button.pressed.connect(func(): GameManager.load_level(level_idx))
		add_child(button)	
