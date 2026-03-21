extends Node2D
class_name FluidFlow

enum Type {
	UNSET,
	WATER,
	ICE_WATER,
}

# Defines a contiguous range of the water flow defined by collisions above it, if any
class WaterPart:
	var y1: int
	var y2: int
	var mask: int
	var is_bottom: bool

	func _init(_y1: int, _y2: int, _mask: int, _is_bottom: bool = false) -> void:
		y1 = _y1
		y2 = _y2
		mask = _mask
		is_bottom = _is_bottom

	# Gets the sprite rects (relative to the emitter) for this vertical region
	func get_rects() -> Array[Rect2i]:
		var res: Array[Rect2i] = []
		var cur_len = 0
		# Include 16 since it'll handle a guy ending at the last pixel
		for i in range(17):
			# Continue the previous rect
			if (1 << i) & mask:
				cur_len += 1
				continue

			# The previous rect ended here
			if cur_len:
				res.append(Rect2i(i - cur_len - 8, y1, cur_len, y2 - y1))
				cur_len = 0
		return res

@export var flow_extent: int = 256  	  # The maximum distance the water can flow downwards
@export var flow_update_speed: int = 128   # How far to extend fluid downward per second, when enabling
@export var is_flow_enabled: bool = true  # Whether the water flow is enabled
@export var flow_type: Type = Type.WATER  # The type of water flow
@export var flow_part_scene: PackedScene  # The scene used for each part of the water flow
@export var flow_offset: int = 1          # Distance below an intersection at which to cut off flow
@export var flow_falloff: int = 8		  # Distance over which the flow fades out at the bottom

var _need_reinstance: bool = false				# Whether flow parts need to be reinstanced
var _flow_parts: Array[WaterPart] = []  		# Parts of water determined by raycast results
var _flow_part_pool: Array[FluidFlowPart] = []  # Flow part object pool

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

func _process(_delta: float) -> void:
	if _need_reinstance:
		_reinstanceFlowParts()
		_need_reinstance = false

func _getRaycastQueries() -> Array[PhysicsRayQueryParameters2D]:
	var res: Array[PhysicsRayQueryParameters2D] = []
	for i in range(16):
		var from = Vector2(_ref_position) + Vector2(i + 0.5, 0)
		var to = from + Vector2(0, _max_flow_height)
		var query = PhysicsRayQueryParameters2D.create(from, to)
		res.append(query)
	return res

func _getFlowPart() -> FluidFlowPart:
	if _flow_part_pool.is_empty():
		var node = flow_part_scene.instantiate() as FluidFlowPart
		add_child(node)
		return node
	else:
		var node = _flow_part_pool.pop_back()
		node.visible = true
		move_child(node, -1)  # Move to front as if we just added it
		return node

# Clear flow sprite instances and instantiate new ones from the current water parts
func _reinstanceFlowParts() -> void:
	# Free old instances
	for node in get_children():
		if node is FluidFlowPart and node.visible:
			node.visible = false
			_flow_part_pool.append(node)

	# Loop in reverse vertical order so lower parts render behind higher parts
	for i in range(_flow_parts.size() - 1, -1, -1):
		var part = _flow_parts[i]

		# Loop through flow sprite rects at this height
		for rect in part.get_rects():
			# Slightly different handling if we have a falloff
			if part.is_bottom and flow_falloff > 0:
				# Draw the node with falloff
				var node = _getFlowPart()

				# Update position and size
				node.position = rect.position
				var size = Vector2i(rect.size.x, min(16, rect.size.y + flow_falloff))
				node.initFlowPart(flow_type, rect.position.x + 8, size, rect.size.y, rect.size.y + flow_falloff)

				# If the falloff is greater than (16 - this height), we need an additional sprite for the rest of the falloff
				if flow_falloff > 16 - rect.size.y:
					var falloff_rect = Rect2i(rect.position.x, rect.position.y + 16, rect.size.x, flow_falloff - (16 - rect.size.y))
					var falloff_node = _getFlowPart()
					falloff_node.position = falloff_rect.position
					falloff_node.initFlowPart(flow_type, falloff_rect.position.x + 8, falloff_rect.size,
												falloff_rect.size.y - flow_falloff, falloff_rect.size.y)
			else:
				# Instantiate a node and add to the scene tree so it's readied
				var node = _getFlowPart()

				# Update position and size
				node.position = rect.position
				node.initFlowPart(flow_type, rect.position.x + 8, rect.size, 16, 16)

func _physics_process(delta: float) -> void:
	if !is_flow_enabled:
		_min_flow_height_f = move_toward(_min_flow_height_f, flow_extent, flow_update_speed * delta)
		_min_flow_height = min(flow_extent, int(_min_flow_height_f))
		return

	_max_flow_height_f = move_toward(_max_flow_height_f, flow_extent, flow_update_speed * delta)
	_max_flow_height = min(flow_extent, int(_max_flow_height_f))

	# If max flow height is done changing, we don't need to recompute raycast queries
	if _max_flow_height < flow_extent:
		_ray_queries = _getRaycastQueries()

	# Raycast downwards at each column to find the water flow
	var space_state = get_world_2d().direct_space_state
	var hits = _ray_hits.duplicate()
	var hit_colliders: Dictionary[Object, Object] = {}
	for i in range(16):
		var hit = space_state.intersect_ray(_ray_queries[i])
		if hit.is_empty():
			# If we intersect nothing, push the max distance we draw water flow
			hits.set(i, _max_flow_height)
			continue

		# Store hit collider in a fake set to trigger callbacks if the hits have changed
		hit_colliders[hit.collider] = null

		# Push the hit distance to the hits array
		hits.set(i, min(_max_flow_height, int(floor(hit.position.y - _ref_position.y)) + flow_offset))

	# If the hits didn't change, we don't need to update the water flow
	# This is like 16 int equality checks but it's like fiiiiiiiiiiiiiine hashing would be more expensive probably
	if hits == _ray_hits: return
	_ray_hits = hits

	# Hits changed; trigger callbacks on hit colliders
	for collider in hit_colliders.keys():
		if collider.has_method("onFluidHit"):
			collider.onFluidHit(flow_type)

	# Update the water flow parts based on the new hits
	_flow_parts.clear()

	# Event sweep my beloved
	var events: Dictionary[int, int] = {}
	for i in range(16):
		var y = hits[i]
		if y not in events: events[y] = (1 << 16) - 1
		events[y] &= ~(1 << i)
	events.sort()

	var prev_y: int = 0
	var mask = (1 << 16) - 1 # Start with all columns flowing
	for y in events.keys():
		# Add parts by blocks of 16 pixels, since animated tile rendering sucks
		# Godot doesn't have a way to do absolute positioned tiling so we put sprites only at
		# positions that are divisible by 16
		for i in range(prev_y - (prev_y % 16), y, 16):
			_flow_parts.append(WaterPart.new(i, min(i + 16, y), mask))
			if i + 16 >= y:
				# This is the bottom part, mark it as such for falloff handling
				_flow_parts.back().is_bottom = true

		mask &= events[y] # Stop flow for columns that hit something at this y
		prev_y = y

	# Add a final part if needed
	if prev_y < _max_flow_height:
		for i in range(prev_y, _max_flow_height, 16):
			_flow_parts.append(WaterPart.new(i, min(i + 16, _max_flow_height), mask))
			if prev_y + 16 >= _max_flow_height:
				# This is the bottom part, mark it as such for falloff handling
				_flow_parts.back().is_bottom = true

	# Reintance flow sprites based on the new parts
	_need_reinstance = true

func enableFlow() -> void:
	if is_flow_enabled: return
	is_flow_enabled = true

	_min_flow_height_f = 0
	_max_flow_height_f = 0
	_min_flow_height = 0
	_max_flow_height = 0

func disableFlow() -> void:
	if !is_flow_enabled: return
	is_flow_enabled = false

	_min_flow_height_f = 0
	_max_flow_height_f = flow_extent
	_min_flow_height = 0
	_max_flow_height = flow_extent

	_ray_hits.fill(0)
	_flow_parts.clear()
	_reinstanceFlowParts()
