extends Node2D
class_name FluidFlow

enum Type {
    WATER,
    ICE_WATER,
}

# Defines a contiguous range of the water flow defined by collisions above it, if any
class WaterPart:
    var y1: int
    var y2: int
    var mask: int

    func _init(_y1: int, _y2: int, _mask: int) -> void:
        y1 = _y1
        y2 = _y2
        mask = _mask

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


@export var max_flow_height: int = 256    # The max height of water flow
@export var is_flow_enabled: bool = true  # Whether the water flow is enabled
@export var flow_type: Type = Type.WATER  # The type of water flow
@export var flow_part_scene: PackedScene  # The scene used for each part of the water flow

var _flow_parts: Array[WaterPart] = []   # Parts of water determined by raycast results
var _flow_sprites: Array[Sprite2D] = []  # The active flow sprite instances

var _ref_position: Vector2i                                # The absolute position of the emitter
var _ray_queries: Array[PhysicsRayQueryParameters2D] = []  # Raycast queries for each column
var _ray_hits: PackedInt32Array = PackedInt32Array()       # Previous raycast hit distances


func _ready() -> void:
    # Get reference position for raycasts and sprite rects
    var pos = global_position.floor()
    _ref_position = Vector2i(pos.x - 8, pos.y)

    # Precompute raycast queries for each column, since they won't change
    for i in range(16):
        var from = Vector2(_ref_position) + Vector2(i + 0.5, 0)
        var to = from + Vector2(0, max_flow_height)
        var query = PhysicsRayQueryParameters2D.create(from, to)
        _ray_queries.append(query)

    # Initialize last hits
    _ray_hits.resize(16)
    if is_flow_enabled:
        _ray_hits.fill(max_flow_height)
    else:
        _ray_hits.fill(0)

# Clear flow sprite instances and instantiate new ones from the current water parts
func _reinstance_flow_sprites() -> void:
    # Free old instances
    for child in get_children():
        if child is FluidFlowPart:
            child.queue_free()
    _flow_sprites.clear()

    # Loop in reverse vertical order so lower parts render behind higher parts
    for i in range(_flow_parts.size() - 1, -1, -1):
        var part = _flow_parts[i]

        # Loop through flow sprite rects at this height
        for rect in part.get_rects():
            print("Instancing flow part at", rect.position, "with size", rect.size)
            # Instantiate a node and add to the scene tree so it's readied
            var node = flow_part_scene.instantiate() as FluidFlowPart
            add_child(node)

            # Update position and size
            node.position = rect.position
            node.resize_flow_part(rect.position.x + 8, rect.size, 16, 16)

func _physics_process(_delta: float) -> void:
    if !is_flow_enabled:
        return

    # Raycast downwards at each column to find the water flow
    var space_state = get_world_2d().direct_space_state
    var hits = _ray_hits.duplicate()
    for i in range(16):
        var hit = space_state.intersect_ray(_ray_queries[i])
        if hit.is_empty():
            # If we intersect nothing, push the max distance we draw water flow
            hits.set(i, max_flow_height)
            continue

        # Push the hit distance to the hits array
        hits.set(i, int(floor(hit.position.y - _ref_position.y)))

    # If the hits didn't change, we don't need to update the water flow
    # This is like 16 int equality checks but it's like fiiiiiiiiiiiiiine hashing would be more expensive probably
    if hits == _ray_hits: return
    _ray_hits = hits

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
        mask &= events[y] # Stop flow for columns that hit something at this y
        prev_y = y

    # Add a final part if needed
    if prev_y < max_flow_height:
        for i in range(prev_y, max_flow_height, 16):
            _flow_parts.append(WaterPart.new(i, min(i + 16, max_flow_height), mask))

    # Reintance flow sprites based on the new parts
    _reinstance_flow_sprites()
