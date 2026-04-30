@tool
extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

@export var area_size: Vector2i = Vector2i(32, 32) :
	set(value):
		area_size = value
		_updateSizes()

func killPenny(candidate: Node):
	if(candidate is Penny):
		candidate.die()
	elif candidate is Slime:
		candidate.in_gas_volume = true

func unkillPenny(candidate: Node):
	if(candidate is Slime):
		candidate.in_gas_volume = false

func _ready():
	body_entered.connect(killPenny)
	body_exited.connect(unkillPenny)
	_updateSizes()

func _updateSizes():
	if not is_node_ready():
		return

	# Update the collision shape size
	collision_shape.shape.size = area_size * 2

	# Update the color rect size
	color_rect.size = area_size * 2
	color_rect.position = -area_size

	# Tell the shader the new area size for proper noise scaling
	color_rect.set_instance_shader_parameter("area_size", Vector2(area_size) * 2.0)
