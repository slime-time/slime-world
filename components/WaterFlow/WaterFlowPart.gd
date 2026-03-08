extends Node2D
class_name WaterFlowPart

@onready var flow_control: Control = $FlowControl
@onready var main_control: Control = $FlowControl/MainFlowControl
@onready var left_flow_part = $FlowControl/RightFlowPart
@onready var main_flow_part = $FlowControl/MainFlowControl/MainFlowPart
@onready var right_flow_part = $FlowControl/RightFlowPart

# Resizes the flow part to the new width
func resize_flow_part(x_offset: int, size: Vector2) -> void:
    flow_control.set_size(size + Vector2(4, 0))
    main_control.set_size(size)
    main_flow_part.position.x = -x_offset
    right_flow_part.position.x = main_control.position.x + main_control.size.x
