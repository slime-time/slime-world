extends Area2D

func _ready():
	body_entered.connect(enterTar)
	body_exited.connect(exitTar)
func enterTar(other: Node2D):
	if(other is PlayerMovement):
		other.tar_intersections += 1
		print(other.tar_intersections)

func exitTar(other: Node2D):
	if(other is PlayerMovement):
		other.tar_intersections -= 1
		print(other.tar_intersections)
		
	
