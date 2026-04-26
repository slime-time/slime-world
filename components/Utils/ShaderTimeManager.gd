extends Node2D

var FRAMERATE: float = 12.0
var _time_offset: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# Update QUANTIZED_TIME for all shaders that need frame time

	# If the game is paused, we don't update the frame time
	# We do, however, update _time_offset so that when we resume the frame time will be correct
	if SceneManager.is_paused:
		_time_offset += delta
		return

	# Otherwise, figure out the current frame time and update the shader parameter
	var effective_time = Time.get_ticks_msec() / 1000.0 - _time_offset

	var quantized_time = floor(effective_time * FRAMERATE) / FRAMERATE
	RenderingServer.global_shader_parameter_set("QUANTIZED_TIME", quantized_time)
