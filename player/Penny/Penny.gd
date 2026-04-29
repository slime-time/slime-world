class_name Penny
extends "res://player/PlayerMovement/PlayerMovement.gd"

var attack_hitbox : Area2D	
	
func _ready():
	super()
	read_movement_data("penny_movement")
	attack_hitbox = get_node("AttackHitbox")
	attack_hitbox.body_entered.connect(deal_damage)
	InputManager.penny_attack.connect(attack)

# If Penny is hit, she takes 1 damage
func hit():
	takeDamage(1)
	
func attack():
	#play animation by changing it
	set_hitbox_state()
	

func set_hitbox_state():
	#temp logic, will use same conditionals as similar function in MeleeSkeleton.gd/SpecialSkeleton.gd
	attack_hitbox.set_visible(!attack_hitbox.visible)
	attack_hitbox.set_monitoring(!attack_hitbox.monitoring)

func deal_damage(target : Node2D):
	if (target is MeleeSkeleton) or (target is RangedSkeleton) or (target is SpecialSkeleton):
		target.hit()
