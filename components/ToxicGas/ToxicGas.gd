extends Area2D

func killPenny(candidate: Node):
	if(candidate is Penny):
		candidate.die()

func _ready():
	body_entered.connect(killPenny)
