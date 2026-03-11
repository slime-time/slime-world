extends Node2D
class_name FluidFlowPart

@onready var mask: TextureRect = $Mask
@onready var flow_control: Control = $Mask/FlowControl
@onready var main_control: Control = $Mask/FlowControl/MainFlowControl
@onready var left_flow_part: AnimatedSprite2D = $Mask/FlowControl/LeftFlowPart
@onready var main_flow_part: AnimatedSprite2D = $Mask/FlowControl/MainFlowControl/MainFlowPart
@onready var right_flow_part: AnimatedSprite2D = $Mask/FlowControl/RightFlowPart

var fluid_type: FluidFlow.Type = FluidFlow.Type.UNSET
var anim_frames: int = 0
var anim_speed: float = 0.0
var anim_duration: float = 0.0

func _ready() -> void:
	var frames = left_flow_part.sprite_frames
	anim_frames = frames.get_frame_count("default")
	anim_speed = frames.get_animation_speed("default")
	anim_duration = anim_frames / anim_speed
	mask.texture = mask.texture.duplicate() as GradientTexture2D

# Resizes the flow part to the new width
func initFlowPart(type: FluidFlow.Type, x_offset: int, size: Vector2, clip_start: int = 16, clip_end: int = 16) -> void:

	fluid_type = type
	flow_control.set_size(size + Vector2(4, 0))
	main_control.set_size(size)
	main_flow_part.position.x = -x_offset
	right_flow_part.position.x = main_control.position.x + main_control.size.x

	mask.texture.fill_from.y = clip_start / 16.0
	mask.texture.fill_to.y = (clip_end + 1) / 16.0

	# Find a time to resume from so that animations are consistent across reinstancing
	var time = Time.get_ticks_msec() / 1000.0;
	var frame = int(fmod(time, anim_duration) * anim_speed) % anim_frames
	var progress = fmod(time, anim_duration) - (frame / anim_speed)

	left_flow_part.set_frame_and_progress(frame, progress)
	main_flow_part.set_frame_and_progress(frame, progress)
	right_flow_part.set_frame_and_progress(frame, progress)
	left_flow_part.play("default")
	main_flow_part.play("default")
	right_flow_part.play("default")
