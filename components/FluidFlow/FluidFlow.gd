extends Node2D
class_name FluidFlow

enum Type {
	UNSET = 0,
	WATER = 1,
	ICE_WATER = 2,
	TAR = 3,
	ENERGIZED = 4,
}

const FLUID_BLOCKING_COLLISION_LAYER = 8;

# The flow materials for each fluid type
const FLOW_MATERIALS: Dictionary[Type, ShaderMaterial] = {
	Type.WATER: preload("res://assets/materials/water_flow.tres"),
	Type.ICE_WATER: preload("res://assets/materials/ice_water_flow.tres"),
	Type.TAR: preload("res://assets/materials/tar_flow.tres"),
	Type.ENERGIZED: preload("res://assets/materials/energized_flow.tres"),
}

@onready var flow_rect: ColorRect = $FlowRect	# The color rect with the fluid flow shader

@export var flow_type: Type = Type.WATER  		# The type of water flow
@export var flow_extent: int = 256  	  		# The maximum distance the water can flow downwards
@export var is_flow_enabled: bool = true  		# Whether the water flow is enabled
@export var flow_fall_accel: int = 0			# Fluid acceleration due to gravity
@export var flow_fall_base_speed: int = 96		# The base velocity at which fluid starts flowing
@export var flow_retract_speed: int = 160		# How far to retract fluid downward per second (in pixels)
@export var flow_offset: int = 2				# How many pixels to extend the flow past the hit point

var _ref_position: Vector2i                                					# The absolute position of the emitter
var _ray_queries: Array[PhysicsRayQueryParameters2D] = []  					# Raycast queries for each column
var _ray_queries_blocking: Array[PhysicsRayQueryParameters2D] = []  		# Raycast queries for each column with blocking layer mask
var _flow_distance_targets: PackedInt32Array = PackedInt32Array()  			# The target flow distance for each column based on raycast hits
var _flow_distance_velocities: PackedFloat32Array = PackedFloat32Array() 	# The current velocity of the flow distance for each column, for accelerating flow falloff
var _flow_distances_f: PackedFloat32Array = PackedFloat32Array() 			# The actual flow distance for each column, gradually extending towards _flow_distance_targets
var _flow_distances: PackedInt32Array = PackedInt32Array()       			# The actual flow distance for each column, as integers for shader parameters
var _flow_start_f: float = 0												# The current starting height of the flow, for animating flow enable/disable
var _flow_start: int = 0													# The current starting height of the flow, as an integer for shader parameters

# Store the base volume level that the water flow should play at, before multiplying
# by the constant global sound effect volume (that may be player-set in a later version) 
const SOUND_VOLUME: float = 5

var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = get_node("WaterAudio")
	AudioManager.setupLocalAudioPlayer(audio_player, true, SOUND_VOLUME, true, "looping_waterfall")
	# Get reference position for raycasts and sprite rects
	var pos = global_position.floor()
	_ref_position = Vector2i(pos.x - 8, pos.y)
	
	# Set the shader material based on the flow type
	flow_rect.material = FLOW_MATERIALS.get(flow_type, null)

	# Initialize arrays
	_flow_distance_targets.resize(16)
	_flow_distance_velocities.resize(16)
	_flow_distance_velocities.fill(flow_fall_base_speed)
	_flow_distances_f.resize(16)
	_flow_distances_f.fill(0)
	_flow_distances.resize(16)
	_flow_distances.fill(0)
	_buildRayQueries()

	# Set up the initial flow state
	if is_flow_enabled:
		enableFlow()
		# If starting enabled, we don't want to animate the flow downward
		_flow_distances_f.fill(float(flow_extent))
		_flow_distances.fill(flow_extent)
	else: disableFlow()


func _buildRayQueries() -> void:
	_ray_queries.resize(16)
	_ray_queries_blocking.resize(16)
	for i in range(16):
		var from = Vector2(_ref_position) + Vector2(i + 0.5, 0)
		var to = Vector2(_ref_position) + Vector2(i + 0.5, flow_extent)
		_ray_queries[i] = PhysicsRayQueryParameters2D.create(from, to)
		_ray_queries_blocking[i] = PhysicsRayQueryParameters2D.create(from, to, 1 << (FLUID_BLOCKING_COLLISION_LAYER - 1))


# Update the shader parameters based on the current flow heights and falloff settings
func _updateShaderParams() -> void:
	# Pass in values that might vary for animation and falloff handling
	flow_rect.set_instance_shader_parameter("flow_start", float(_flow_start))

	# Pass in the flow distance for each column
	# Instance parameters don't support arrays, so we batch four columns into each ivec4 parameter
	flow_rect.set_instance_shader_parameter("flow_distances_0", Vector4i(_flow_distances[0], _flow_distances[1], _flow_distances[2], _flow_distances[3]))
	flow_rect.set_instance_shader_parameter("flow_distances_4", Vector4i(_flow_distances[4], _flow_distances[5], _flow_distances[6], _flow_distances[7]))
	flow_rect.set_instance_shader_parameter("flow_distances_8", Vector4i(_flow_distances[8], _flow_distances[9], _flow_distances[10], _flow_distances[11]))
	flow_rect.set_instance_shader_parameter("flow_distances_12", Vector4i(_flow_distances[12], _flow_distances[13], _flow_distances[14], _flow_distances[15]))


# Extends flow distances towards their targets
func _extendFlows(delta: float) -> void:
	for i in range(16):
		# Model acceleration due to gravity
		var old_velocity = _flow_distance_velocities[i]
		_flow_distance_velocities[i] += flow_fall_accel * delta

		# Compute the integrated distance change
		var delta_distance = (old_velocity + _flow_distance_velocities[i]) * 0.5 * delta

		_flow_distances_f[i] = move_toward(_flow_distances_f[i], _flow_distance_targets[i], delta_distance)
		_flow_distances[i] = min(int(_flow_distances_f[i]), flow_extent)


# Collect all (not necessarily blocking) hits within the flow area for a ray query
func _getFluidRayHits(space_state: PhysicsDirectSpaceState2D) -> Array[Object]:
	var hits: Dictionary[Object, Object] = {}	# Fake set for colliders we hit
	for i in range(16):
		var hit = space_state.intersect_ray(_ray_queries[i])
		if not hit.is_empty():
			var hit_dist_f = hit.position.y - _ref_position.y
			if hit_dist_f >= _flow_start_f and hit_dist_f < _flow_distances_f[i]:
				# Within the flow area; put it in our collider callback set
				hits[hit.collider] = null
	return hits.keys()


func _physics_process(delta: float) -> void:
	# Extend the flows downward towards their current targets
	_extendFlows(delta)

	if !is_flow_enabled:
		_flow_start_f = move_toward(_flow_start_f, flow_extent, flow_retract_speed * delta)
		_flow_start = min(int(_flow_start_f), flow_extent)

		# When flow is disabled, we still query non-blocking hits to trigger callbacks for transformation
		var space_state = get_world_2d().direct_space_state
		var hit_colliders = _getFluidRayHits(space_state)
		for collider in hit_colliders:
			if collider.has_method("onFluidHit"):
				collider.onFluidHit(flow_type)

		# Make sure shader parameters are updated wiht extended start and flow distances
		_updateShaderParams()
		return

	# Raycast downwards at each column to find the water flow
	var space_state = get_world_2d().direct_space_state
	var hit_colliders = _getFluidRayHits(space_state)	# Collect non-blocking hits

	# Now handle blocking hits
	for i in range(16):
		var hit_blocking = space_state.intersect_ray(_ray_queries_blocking[i])
		if hit_blocking.is_empty():
			# If we intersect nothing, the distance target for this column is the full flow extent
			_flow_distance_targets[i] = flow_extent
			continue

		# Now, determine if this hit is actually within the flow area for this column
		var hit_dist_f = hit_blocking.position.y - _ref_position.y
		var new_target = min(flow_extent, int(floor(hit_dist_f)) + flow_offset)
		if hit_dist_f >= 0 and hit_dist_f < _flow_distances_f[i]:
			# Update the distance target for this column based on the hit_blocking
			_flow_distance_targets[i] = new_target
			_flow_distances_f[i] = min(_flow_distances_f[i], float(new_target))
			_flow_distances[i] = min(_flow_distances[i], new_target)

			# If we updated the distance target, reset velocity for this column
			_flow_distance_velocities[i] = flow_fall_base_speed
		elif hit_dist_f >= 0:
			# Not within the flow area but we need to change our target
			_flow_distance_targets[i] = new_target

	# Update shader parameters with new flow distances
	_updateShaderParams()

	# Trigger callbacks on colliders we hit within the flow area
	for collider in hit_colliders:
		if collider.has_method("onFluidHit"):
			collider.onFluidHit(flow_type)


func toggleFlow() -> void:
	if(is_flow_enabled):
		disableFlow()
	else:
		enableFlow()

func enableFlow() -> void:
	if not (audio_player.playing):
		audio_player.play()
	if is_flow_enabled: return
	is_flow_enabled = true
	
	
	_flow_start_f = 0
	_flow_start = 0
	_flow_distance_targets.fill(flow_extent)
	_flow_distances_f.fill(0)
	_flow_distances.fill(0)
	_updateShaderParams()


func disableFlow() -> void:
	if !is_flow_enabled: return
	is_flow_enabled = false
	
	audio_player.stop()
	
	_flow_start_f = 0
	_flow_start = 0
	# We don't update the distance targets because we want flows to keep extending
	_updateShaderParams()
