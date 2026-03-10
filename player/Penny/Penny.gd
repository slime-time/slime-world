class_name Penny
extends "res://player/PlayerMovement/PlayerMovement.gd"

	
func _ready():
	super()
	read_movement_data("penny_movement")

# If Penny is hit by a spike, she takes 1 damage
func spikeHit():
	takeDamage(1)
