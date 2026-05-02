extends GridContainer

const MainMenuButton = preload("res://components/MainMenuButton/MainMenuButton.tscn")

func _ready() -> void:
	reload()

func reload() -> void:
	for child in get_children():
		child.queue_free()


	# Add level buttons
	for level_idx in range(1, GameManager.levels.size()):
		var button = MainMenuButton.instantiate()
		
		button.text = "Level " + str(level_idx)

		# Disable button if level hasn't been unlocked yet
		if (level_idx > GameManager.current_state.highest_level_unlocked):
			button.disabled = true;

		# Give it functionality
		button.pressed.connect(func(): 
			GameManager.call_deferred("loadLevel", level_idx))

		# Actually place the button into the scene
		add_child(button)	