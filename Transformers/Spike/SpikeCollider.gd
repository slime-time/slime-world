extends Area2D

# Signal sent when the player goes below this spike
signal player_entered


# An entity has entered the hitbox, check if it is a player 
func entityEntered(entity):
	if(entity is PlayerMovement):
		# If it is a player, drop the spike
		player_entered.emit()
		


func _ready():
	player_entered.connect(get_parent().fall)
	body_entered.connect(entityEntered)
