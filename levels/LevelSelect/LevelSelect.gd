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

		# Give it functionality
		button.pressed.connect(func(): GameManager.call_deferred("load_level", level_idx))

		# Actually place the button into the scene
		add_child(button)	
