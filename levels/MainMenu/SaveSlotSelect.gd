extends GridContainer

const MainMenuButton = preload("res://components/MainMenuButton/MainMenuButton.tscn")

func _ready() -> void:
	reload()

func reload() -> void:
	for child in get_children():
		child.queue_free()
	
	var all_save_slots : Array = GameState.loadAllSaveSlots()

	if (all_save_slots.size() == 0):
		var label = Label.new()
		label.text = "No save slots found,\nplease create a new\ngame to start playing!"

		# Make look good
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var label_settings = LabelSettings.new()
		label_settings.font = load("res://assets/fonts/Silkscreen/Silkscreen-Regular.ttf")
		label_settings.font_size = 12
		label.label_settings = label_settings

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
