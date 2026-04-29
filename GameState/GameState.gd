extends Node
class_name GameState

# Static array of what values are saved to disk and which are not
const _SAVED_KEYS : Array[String] = [
	"player_name",
	"highest_level_unlocked",
]
 
# All values in the game state, with defaults that make sense for a new game. 
# These will be overridden by the save file if it exists.
var save_slot : int = -1
func _getSaveSlotName() -> String:
	if save_slot == -1:
		push_error("Save slot not set, returning default name")
		return "no_save_slot"
	else:
		return "save_slot_" + str(save_slot)

var player_name : String = "Penny"
var highest_level_unlocked : int = 1
var cur_level: int = 0 # Level 0 is the level select screen
	
static func _getSaveFile() -> ConfigFile:
	var save_file : ConfigFile = ConfigFile.new()

	var err = save_file.load("user://save_file.cfg")
	if err == OK:
		return save_file
	
	# If the file doesn't exist, we want to create it with the default values and return it
	elif err == ERR_FILE_NOT_FOUND:
		print("Save file not found, creating new one with default values.")

		save_file.set_value("global", "count_save_slots", 0)

		if save_file.save("user://save_file.cfg") == OK:
			return save_file

	push_error("Couldn't load or create save file, error code: " + str(err))
	return save_file # Return the save file even if it failed to load, so that we can attempt to save to it later.

static func _saveFileToDisk(save_file : ConfigFile) -> void:
	var err = save_file.save("user://save_file.cfg")
	if err != OK:
		push_error("Couldn't save to disk, error code: " + str(err))

## Loads the save slot data into the current game state. If slot_num is -1, will create a new save slot. Otherwise, if slot doesn't exist, will do nothing. 
func loadSaveSlot(slot_num : int) -> void:
	var save_file : ConfigFile = _getSaveFile()

	if slot_num == -1:
		# Create a new save slot
		save_slot = save_file.get_value("global", "count_save_slots", 0)
		save_file.set_value("global", "count_save_slots", save_slot + 1)
		
		# Save these default values to the new save slot in the save file
		for key in _SAVED_KEYS:
			save_file.set_value(_getSaveSlotName(), key, self.get(key))
		
		_saveFileToDisk(save_file)
	
	else:
		self.save_slot = slot_num

		# Load an existing save slot, if it exists. Otherwise, do nothing.
		if not save_file.has_section(_getSaveSlotName()):
			push_error("Save slot " + str(slot_num) + " doesn't exist, can't load.")
			return
		
		for key in _SAVED_KEYS:
			self.set(key, save_file.get_value(_getSaveSlotName(), key))
		
## Saves given keys. By default, saves all keys in _SAVED_KEYS.
func saveKeys(keys_to_save : Array[String] = _SAVED_KEYS) -> void:
	var save_file : ConfigFile = _getSaveFile()

	for key in keys_to_save:
		if not _SAVED_KEYS.has(key):
			push_error("Key " + key + " is not in the list of saved keys, so it won't be saved. Skipping.")
			continue

		save_file.set_value(_getSaveSlotName(), key, self.get(key))
	
	_saveFileToDisk(save_file)

static func loadAllSaveSlots() -> Array:
	var save_file : ConfigFile = GameState._getSaveFile()
	var count_save_slots : int = save_file.get_value("global", "count_save_slots", 0)

	return range(count_save_slots).map(func(slot_num) -> GameState: 
		var game_state = GameState.new()
		game_state.loadSaveSlot(slot_num)
		return game_state
	)
