extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Add level buttons
	for level_idx in range(1, GameManager.levels.size()):
		var button = Button.new()
		
		button.custom_minimum_size = Vector2(100, 50)
		button.text = "Level " + str(level_idx)

		# Disable button if level hasn't been unlocked yet
		if (level_idx > GameManager.highest_level_unlocked):
			button.disabled = true;

		button.pressed.connect(func(): GameManager.load_level(level_idx))
		add_child(button)	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
