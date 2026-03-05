extends CollisionPolygon2D

func _ready():
	set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	
func fall():
	set_process_mode(Node.PROCESS_MODE_INHERIT)
