extends GridContainer

const MainMenuButton = preload("res://components/MainMenuButton/MainMenuButton.tscn")

func _ready() -> void:
	var all_save_slots : Array = GameState.loadAllSaveSlots()

	if (all_save_slots.size() == 0):
		var label = Label.new()
		label.text = "No save slots found, please create a new game to start playing!"
		add_child(label)
		return

	# Add save_slot buttons
	for save_slot in all_save_slots:
		var button = MainMenuButton.instantiate()
		
		button.text = "Save Slot " + str(save_slot.save_slot + 1) # 1 index

		# Give it functionality
		button.pressed.connect(func(): 
			GameManager.current_state.loadSaveSlot(save_slot.save_slot) # Load the save slot data into the current game state
			GameManager.call_deferred("loadLevel", 0)
		)

		# Actually place the button into the scene
		add_child(button)	
