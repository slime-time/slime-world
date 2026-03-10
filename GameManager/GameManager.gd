extends Node

var cur_level: int = 0 # Level 0 is LevelSelect
var highest_level_unlocked: int = 1

const levels: Array[String] = [
	"res://levels/LevelSelect/LevelSelectScreen.tscn",
	"res://levels/TestLevel.tscn",
	"res://levels/SpikeTest.tscn",
    "res://levels/FluidTestLevel.tscn"
]

func load_level(x : int):
	assert(0 <= x && x <= highest_level_unlocked)
	cur_level = x
	get_tree().call_deferred("change_scene_to_file", levels[x])

func complete_level():
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

	load_level(nxt)
