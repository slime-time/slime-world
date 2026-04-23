extends Node2D
class_name FluidVolume

@export var fluid_type: FluidFlow.Type = FluidFlow.Type.WATER				# The type of fluid in this volume
@export var fluid_level: int = 8											# The level of the fluid
@export var fluid_extent_left: int = 32										# How far, at most, the fluid extends left from the volume's origin
@export var fluid_extent_right: int = 32									# How far, at most, the fluid extends right from the volume's origin
@export var fluid_velocity: float = 0.0										# The horizontal velocity at which the fluid flows (±x)
@export var visual_fluid_velocity: float = 0.0								# The horizontal velocity at which the fluid shader flows (±x)
@export var blocking_corner_radius: int = 1;								# How far to round inside corners, to fill out pixel gaps in the tilemap blocked by a collider corner

@onready var fluid_rect: ColorRect = $FluidRect								# The color rect we render the fluid shader on
@onready var fluid_area: Area2D = $FluidArea								# The area we use for fluid interactions
@onready var fluid_collider: CollisionShape2D = $FluidArea/FluidCollider	# The collider we use for fluid interactions

var _origin: Vector2														# The absolute position of the fluid volume's origin
var _min_left_extent: int = 0												# The minimum left extent of the fluid, based on raycasts
var _max_right_extent: int = 0												# The maximum right extent of the fluid, based on raycasts
var _fluid_rect_size: Vector2												# The size of the fluid rect, based on fluid extents but always with fixed height
var _fluid_extents_left: PackedInt32Array = PackedInt32Array()				# The left extents of flow from the origin, for each row increasing from 0 at the bottom
var _fluid_extents_right: PackedInt32Array = PackedInt32Array()				# The right extents ^

func _setShaderParameters() -> void:
	# Set primary settings
	fluid_rect.set_instance_shader_parameter("fluid_rect_size", _fluid_rect_size)
	fluid_rect.set_instance_shader_parameter("fluid_level", fluid_level)
	fluid_rect.set_instance_shader_parameter("fluid_velocity", visual_fluid_velocity)

	# Set the fluid extents
	for i in range(0, 16, 4):
		var left = Vector4(_fluid_extents_left[i], _fluid_extents_left[i + 1], _fluid_extents_left[i + 2], _fluid_extents_left[i + 3])
		var right = Vector4(_fluid_extents_right[i], _fluid_extents_right[i + 1], _fluid_extents_right[i + 2], _fluid_extents_right[i + 3])

		# We have to offset the fluid extents such that the leftmost extent is zero
		for j in range(4):
			# Fill out rounded corners
			var left_offset = 0
			var right_offset = 0
			for k in range(-blocking_corner_radius, blocking_corner_radius + 1):
				if i + j + k < 0 or i + j + k >= 16: continue

				# If we are part of a corner k pixels away, we extend to the left relative to how far away the rounding starts
				# Sim. for right
				if _fluid_extents_left[i + j + k] < left[j]:
					left_offset = max(left_offset, blocking_corner_radius - abs(k) + 1)
				if _fluid_extents_right[i + j + k] > right[j]:
					right_offset = max(right_offset, blocking_corner_radius - abs(k) + 1)

			# Offset for the normalized shader coordinates
			left[j] -= _min_left_extent + left_offset
			right[j] -= _min_left_extent - right_offset

		# Set the actual extents for this row batch on the shader instance
		fluid_rect.set_instance_shader_parameter("extents_left_" + str(i), left)
		fluid_rect.set_instance_shader_parameter("extents_right_" + str(i), right)

func _ready() -> void:
	_updateFluidExtents.call_deferred()

func _onBodyEntered(body: Node2D) -> void:
	if body is PlayerMovement:
		body.enterFluidVolume(Vector2(fluid_velocity, 0))

func _onBodyExited(body: Node2D) -> void:
	if body is PlayerMovement:
		body.exitFluidVolume(Vector2(fluid_velocity, 0))

func _updateFluidExtents() -> void:
	_origin = global_position.floor()
	_fluid_extents_left.resize(16)
	_fluid_extents_right.resize(16)
	_fluid_extents_left.fill(0)
	_fluid_extents_right.fill(0)

	# For each row, raycast in both directions to determine the bounds of flow
	var blocking_mask = 1 << (FluidFlow.FLUID_BLOCKING_COLLISION_LAYER - 1)
	for i in range(fluid_level):
		var from = _origin - Vector2(0, i + 0.5)
		var to_left = _origin - Vector2(fluid_extent_left, i + 0.5)

		var left_query = PhysicsRayQueryParameters2D.create(from, to_left, blocking_mask)
		var left_result = get_world_2d().direct_space_state.intersect_ray(left_query)
		if left_result.is_empty():
			_fluid_extents_left[i] = -fluid_extent_left
		else:
			_fluid_extents_left[i] = int(left_result.position.x - _origin.x)

		var to_right = _origin + Vector2(fluid_extent_right, -i - 0.5)
		var right_query = PhysicsRayQueryParameters2D.create(from, to_right, blocking_mask)
		var right_result = get_world_2d().direct_space_state.intersect_ray(right_query)
		if right_result.is_empty():
			_fluid_extents_right[i] = fluid_extent_right
		else:
			_fluid_extents_right[i] = int(right_result.position.x - _origin.x)

	# Find the overall bounds of the fluid from sided extents
	_min_left_extent = 0
	_max_right_extent = 0
	for i in range(0, fluid_level):
		_min_left_extent = min(_min_left_extent, _fluid_extents_left[i])
		_max_right_extent = max(_max_right_extent, _fluid_extents_right[i])
	_fluid_rect_size = Vector2(_max_right_extent - _min_left_extent, 24)

	# Set the color rect offsets to match
	fluid_rect.offset_left = _min_left_extent
	fluid_rect.offset_right = _max_right_extent

	# Set the collider extents to match
	var width = _max_right_extent - _min_left_extent
	var height = fluid_level
	fluid_collider.shape.size = Vector2(width, height)

	# CollisionShape2D position is based on its center
	fluid_collider.position.x = (_min_left_extent + _max_right_extent) / 2.0
	fluid_collider.position.y = -height / 2.0

	# Set shader parameters on the color rect
	_setShaderParameters()
