extends Node

var cur_level: int = 0 # Level 0 is the level select screen
var highest_level_unlocked: int = 1

const levels: Array[String] = [
	"res://levels/MainMenu/MainMenu.tscn",
	"res://levels/Tutorial1.tscn",
	"res://levels/Level1.tscn",
	"res://levels/Level2.tscn"
]

func loadLevel(x : int):
	assert(0 <= x && x <= highest_level_unlocked)
	cur_level = x
	get_tree().call_deferred("change_scene_to_file", levels[x])

## Completes the current level we're on and loads next level if one was just unlocked
func completeLevel():
	var nxt : int = cur_level

	# Unlock the next level
	if (highest_level_unlocked == cur_level):
		highest_level_unlocked += 1
		nxt += 1

	# Otherwise, go back to level select
	else:
		nxt = 0

	# Oops we beat the game
	if (nxt == levels.size()):
		nxt = 0

	loadLevel(nxt)
