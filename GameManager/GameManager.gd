extends Node

const levels: Array[String] = [
	"res://levels/MainMenu/MainMenu.tscn",
	"res://levels/1-1.tscn",
	"res://levels/1-2.tscn",
	"res://levels/1-4.tscn",
	"res://levels/2-1.tscn",
	"res://levels/3-1.tscn",
	"res://levels/3-2.tscn",
	"res://levels/3-4.tscn",
	"res://levels/3-3.tscn",
	"res://levels/3-5.tscn",
	"res://levels/4-1.tscn",
	"res://levels/4-2.tscn",
	"res://levels/4-3.tscn",
	"res://levels/4-4.tscn",
	"res://levels/5-1.tscn",
	"res://levels/5-2.tscn",
	"res://levels/5-3.tscn"
]

signal level_changed

var current_state : GameState = GameState.new()

func loadLevel(x : int):
	assert(0 <= x && x <= current_state.highest_level_unlocked)
	current_state.cur_level = x
	#avoid playing level themes on title
	if x != 0:
		level_changed.emit()
	get_tree().call_deferred("change_scene_to_file", levels[x])
	

## Completes the current level we're on and loads next level if one was just unlocked
func completeLevel():
	var nxt : int = current_state.cur_level

	# Unlock the next level
	if (current_state.highest_level_unlocked == current_state.cur_level):
		current_state.highest_level_unlocked += 1
		current_state.saveKeys(["highest_level_unlocked"])
		nxt += 1

	# Otherwise, go back to level select
	else:
		nxt = 0

	# Oops we beat the game
	if (nxt == levels.size()):
		nxt = 0

	loadLevel(nxt)
