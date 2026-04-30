class_name Penny
extends "res://player/PlayerMovement/PlayerMovement.gd"


var attack_hitbox : Area2D	
var sprite

	
func _ready():
	super()
	read_movement_data("penny_movement")
	attack_hitbox = get_node("AttackArea")
	sprite = get_node("PennySprite")
	InputManager.penny_attack.connect(attack)
	penny_flip.connect(flip)

# If Penny is hit, she takes 1 damage
func hit():
	takeDamage(1)
	
	
func flip(direction : float):
	print(direction)
	if (direction < 0 and sprite.flip_h) or (direction > 0 and !sprite.flip_h):
		return
	else: 
		sprite.flip_h = !sprite.flip_h
		attack_hitbox.position.x = -attack_hitbox.position.x
		attack_hitbox.scale = -attack_hitbox.scale
	
func attack():
	#play animation
	var bodies = attack_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name == "SkeletonHurtbox":
			body.hit()  
	
	
