class_name Penny
extends "res://player/PlayerMovement/PlayerMovement.gd"

var attack_hitbox : Area2D	
	
func _ready():
	super()
	read_movement_data("penny_movement")
	attack_hitbox = get_node("AttackArea")
	InputManager.penny_attack.connect(attack)

# If Penny is hit, she takes 1 damage
func hit():
	takeDamage(1)
	
func attack():
	#play animation
	var bodies = attack_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name == "SkeletonHurtbox":
			body.hit()  
	
	
