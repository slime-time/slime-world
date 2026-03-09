extends Node2D
class_name FluidFlowPart

@onready var mask_texture: GradientTexture2D = $Mask.texture as GradientTexture2D
@onready var flow_control: Control = $Mask/FlowControl
@onready var main_control: Control = $Mask/FlowControl/MainFlowControl
@onready var left_flow_part = $Mask/FlowControl/RightFlowPart
@onready var main_flow_part = $Mask/FlowControl/MainFlowControl/MainFlowPart
@onready var right_flow_part = $Mask/FlowControl/RightFlowPart

# Resizes the flow part to the new width
func resize_flow_part(x_offset: int, size: Vector2, clip_start: int = 16, clip_end: int = 16) -> void:
    flow_control.set_size(size + Vector2(4, 0))
    main_control.set_size(size)
    main_flow_part.position.x = -x_offset
    right_flow_part.position.x = main_control.position.x + main_control.size.x

    mask_texture.fill_from.y = clip_start / 16.0
    mask_texture.fill_to.y = (clip_end + 1) / 16.0
