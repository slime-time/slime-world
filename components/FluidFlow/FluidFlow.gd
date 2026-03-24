extends Node2D
class_name FluidFlow

enum Type {
	UNSET,
	WATER,
	ICE_WATER,
}

# The flow materials for each fluid type
const FLOW_MATERIALS: Dictionary[Type, ShaderMaterial] = {
	Type.WATER: preload("res://assets/materials/water_flow.tres"),
	Type.ICE_WATER: preload("res://assets/materials/ice_water_flow.tres"),
}

@onready var flow_rect: ColorRect = $FlowRect	# The color rect with the fluid flow shader

@export var flow_type: Type = Type.WATER  			# The type of water flow
@export var flow_animation_framerate: int = 8  		# The framerate of the fluid flow animation
@export var flow_extent: int = 256  	  			# The maximum distance the water can flow downwards
@export var is_flow_enabled: bool = true  			# Whether the water flow is enabled
@export var flow_update_speed: int = 128  			# How far to extend fluid downward per second, when enabling
@export var flow_update_speed_disable: int = 128	# Speed of updating flow start height when disabling
@export var flow_falloff_top: int = 8	  			# Distance over which the flow fades out at the top
@export var flow_falloff: int = 8		  			# Distance over which the flow fades out at the bottom
@export var flow_offset: int = 2					# How many pixels to extend the flow past the hit point

var _ref_position: Vector2i                                # The absolute position of the emitter
var _ray_queries: Array[PhysicsRayQueryParameters2D] = []  # Raycast queries for each column
var _ray_hits: PackedInt32Array = PackedInt32Array()       # Previous raycast hit distances

var _min_flow_height_f: float = 0
var _max_flow_height_f: float = 256

var _min_flow_height: int = 0    # The starting position of water flow
var _max_flow_height: int = 256  # The max height of water flow currently


func _ready() -> void:
	# Get reference position for raycasts and sprite rects
	var pos = global_position.floor()
	_ref_position = Vector2i(pos.x - 8, pos.y)

	# Precompute raycast queries for each columns
	_ray_queries = _getRaycastQueries()

	# Initialize last hits
	_ray_hits.resize(16)
	if is_flow_enabled:
		_ray_hits.fill(_max_flow_height)
		_min_flow_height_f = 0
		_max_flow_height_f = flow_extent
	else:
		_ray_hits.fill(0)
		_min_flow_height_f = 0
		_max_flow_height_f = 0

	# Set the shader material based on the flow type
	flow_rect.material = FLOW_MATERIALS.get(flow_type, null)


func _getRaycastQueries() -> Array[PhysicsRayQueryParameters2D]:
	var res: Array[PhysicsRayQueryParameters2D] = []
	for i in range(16):
		var from = Vector2(_ref_position) + Vector2(i + 0.5, 0)
		var to = Vector2(_ref_position) + Vector2(i + 0.5, _max_flow_height_f)
		var query = PhysicsRayQueryParameters2D.create(from, to)
		res.append(query)
	return res


# Update the shader parameters based on the current flow heights and falloff settings
func _updateShaderParams() -> void:
	# Pass in values that might vary for animation and falloff handling
	flow_rect.set_instance_shader_parameter("flow_extent", flow_extent)
	flow_rect.set_instance_shader_parameter("flow_start", _min_flow_height_f)
	flow_rect.set_instance_shader_parameter("flow_end", _max_flow_height_f)
	flow_rect.set_instance_shader_parameter("flow_falloff_top", flow_falloff_top)
	flow_rect.set_instance_shader_parameter("flow_falloff_bottom", flow_falloff)

	# Pass in the flow distance for each column
	# Instance parameters don't support arrays, so we batch four columns into each ivec4 parameter
	flow_rect.set_instance_shader_parameter("flow_distances_0", Vector4i(_ray_hits[0], _ray_hits[1], _ray_hits[2], _ray_hits[3]))
	flow_rect.set_instance_shader_parameter("flow_distances_4", Vector4i(_ray_hits[4], _ray_hits[5], _ray_hits[6], _ray_hits[7]))
	flow_rect.set_instance_shader_parameter("flow_distances_8", Vector4i(_ray_hits[8], _ray_hits[9], _ray_hits[10], _ray_hits[11]))
	flow_rect.set_instance_shader_parameter("flow_distances_12", Vector4i(_ray_hits[12], _ray_hits[13], _ray_hits[14], _ray_hits[15]))

	# Compute the current animation frame
	var time = Time.get_ticks_usec() / 1000000.0
	var frame = int(time * flow_animation_framerate) % 16
	flow_rect.set_instance_shader_parameter("frame_index", frame)


func _process(_delta: float) -> void:
	# Update shader parameters for animation even if flow is disabled,
	# since we might still want the flow texture to animate while not flowing
	_updateShaderParams()


func _physics_process(delta: float) -> void:
	if !is_flow_enabled:
		_min_flow_height_f = move_toward(_min_flow_height_f, flow_extent, flow_update_speed_disable * delta)
		_min_flow_height = min(flow_extent, int(_min_flow_height_f))

		# For now, we don't bother raycasting while flow is disabled
		# We can avoid breaking out here to still trigger fluid callbacks while fluid is disabling
		return

	_max_flow_height_f = move_toward(_max_flow_height_f, flow_extent, flow_update_speed * delta)
	_max_flow_height = min(flow_extent, int(_max_flow_height_f))

	# If max flow height is done changing, we don't need to recompute raycast queries
	if _max_flow_height < flow_extent:
		_ray_queries = _getRaycastQueries()

	# Raycast downwards at each column to find the water flow
	var space_state = get_world_2d().direct_space_state
	var hits_changed = false
	var hit_colliders: Dictionary[Object, Object] = {}
	for i in range(16):
		var hit = space_state.intersect_ray(_ray_queries[i])
		if hit.is_empty():
			# If we intersect nothing, push the max distance we draw water flow
			if _ray_hits.get(i) != _max_flow_height:
				_ray_hits.set(i, _max_flow_height)
				hits_changed = true
			continue

		# Store hit collider in a fake set to trigger callbacks if the hits have changed
		hit_colliders[hit.collider] = null

		# Push the hit distance to the hits array
		var hit_dist = min(_max_flow_height, int(floor(hit.position.y - _ref_position.y)) + flow_offset)
		if _ray_hits.get(i) != hit_dist:
			_ray_hits.set(i, hit_dist)
			hits_changed = true

	# If the hits didn't change, we don't need to trigger callbacks anew
	# Note we will still call the fluid hit callback multiple times potentially, so do not rely on a single call
	if !hits_changed: return

	# Hits changed; trigger callbacks on hit colliders
	for collider in hit_colliders.keys():
		if collider.has_method("onFluidHit"):
			collider.onFluidHit(flow_type)


func enableFlow() -> void:
	if is_flow_enabled: return
	is_flow_enabled = true

	_min_flow_height_f = 0
	_max_flow_height_f = 0
	_min_flow_height = 0
	_max_flow_height = 0
	_ray_hits.fill(0)


func disableFlow() -> void:
	if !is_flow_enabled: return
	is_flow_enabled = false

	_min_flow_height_f = 0
	_max_flow_height_f = flow_extent
	_min_flow_height = 0
	_max_flow_height = flow_extent

	_ray_hits.fill(0)
