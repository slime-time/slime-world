class_name Penny
extends "res://player/PlayerMovement/PlayerMovement.gd"


var attack_hitbox : Area2D	
var sprite : AnimatedSprite2D
	
func _ready():
	super()
	read_movement_data("penny_movement")
	attack_hitbox = get_node("AttackHitbox")
	sprite = get_node("PennySprite")
	sprite.animation_changed.connect(sprite.play)
	sprite.frame_changed.connect(set_hitbox_state)
	sprite.animation_finished.connect(func(): sprite.set_animation("walk"))
	sprite.set_animation("walk")
	attack_hitbox.body_entered.connect(deal_damage)
	InputManager.penny_attack.connect(attack)
	penny_flip.connect(flip)

func _process(delta: float) -> void:
	if !is_on_floor() or sprite.animation == "walk" and velocity.x == 0:
		sprite.stop()
	else:
		sprite.play()

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
	sprite.set_animation("attack")
	

func set_hitbox_state():
	if(sprite.animation == "attack"):
		if(sprite.frame == 3):
			AudioManager.play_sfx("swordswing", 1, -0.5, 1.5)
			attack_hitbox.set_monitoring(true)
		if(sprite.frame == 6):
			attack_hitbox.set_monitoring(false)

func deal_damage(target : Node2D):
	if (target is MeleeSkeleton) or (target is RangedSkeleton) or (target is SpecialSkeleton):
		target.hit()
