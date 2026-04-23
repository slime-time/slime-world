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
func getSaveSlotName() -> String:
    if save_slot == -1:
        push_error("Save slot not set, returning default name")
        return "no_save_slot"
    else:
        return "save_slot_" + str(save_slot)

var player_name : String = "Penny"
var highest_level_unlocked : int = 1
var cur_level: int = 0 # Level 0 is the level select screen
    
func serialize() -> Dictionary:
    var dict : Dictionary = {}
    for key in _SAVED_KEYS:
        dict[key] = self.get(key)
    return dict

func getSaveFile() -> ConfigFile:
    var save_file : ConfigFile = ConfigFile.new()

    var err = save_file.load("user://save_file.cfg")
    if err == OK:
        return save_file
    
    # If the file doesn't exist, we want to create it with the default values and return it
    elif err == ERR_FILE_NOT_FOUND:
        save_file.set_value("global", "count_save_slots", 0)

        if save_file.save("user://save_file.cfg") == OK:
            return save_file

    push_error("Couldn't load or create save file, error code: " + str(err))
    return save_file # Return the save file even if it failed to load, so that we can attempt to save to it later.

func saveFileToDisk(save_file : ConfigFile) -> void:
    var err = save_file.save("user://save_file.cfg")
    if err != OK:
        push_error("Couldn't save to disk, error code: " + str(err))