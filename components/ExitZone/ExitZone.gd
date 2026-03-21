extends Area2D

# Store if this zone has been used to win, to avoid completing a level twice and counting towards
# Progress both times
var has_won = false
func handleEntry(body: Node2D):
	# If the player reaches the end as Penny in human form, they win!
	if(body is Penny and not has_won):
		has_won = true
		GameManager.complete_level()
		

func _ready():
	body_entered.connect(handleEntry)
	
