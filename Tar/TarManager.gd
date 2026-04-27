extends Node2D
@warning_ignore_start("integer_division")

const TAR_LAYER_SCENE = preload("res://components/TarLayer/TarLayer.tscn")
var tar_layer: TarLayer = null

# Each bit is 1 if there is a tar glob at the cooresponding location, otherwise 0
var tar_globs: PackedByteArray


const GLOB_SIZE: int = 4

var window_height: int
var window_width: int
func _ready():
	var window_size = get_window().get_content_scale_size()
	window_height = window_size.y
	window_width = window_size.x
	tar_globs.resize((window_height * window_width) / 8)
	resetTar()

	# Connect tar layer loading and do it now for the first scene (doesn't matter if it's instantiated in menus)
	get_tree().root.child_entered_tree.connect(_onRootChildAdded)
	call_deferred("_onSceneLoaded", get_tree().current_scene)

# Runs when a direct child of the root node is added so we can detect when a new scene is loaded
func _onRootChildAdded(node : Node2D) -> void:
	_onSceneLoaded.call_deferred(node)

# Runs on the next update after a direct child node of the root is added (potentially a new scene loaded)
func _onSceneLoaded(node : Node2D) -> void:
	# Don't do anything if the node that was added isn't the current scene
	if node != get_tree().get_current_scene():
		return

	# If the scene isn't ready yet, wait for it to be ready
	if node.is_node_ready():
		_onSceneReady()
	else:
		node.ready.connect(_onSceneReady)

# Runs when a newly loaded scene becomes ready
func _onSceneReady() -> void:
	# Instantiate the tar layer and add it to the scene
	tar_layer = TAR_LAYER_SCENE.instantiate()
	get_tree().get_current_scene().add_child(tar_layer)

# Get the coordinates that the slime glob object should be placed at
func convertToCoordinates(x: float, y: float) -> Vector2i:
	var round_x: int = GLOB_SIZE * (min(max(0, roundi(x)), window_width) / GLOB_SIZE)
	var round_y: int = GLOB_SIZE * (min(max(0, roundi(y)), window_height) / GLOB_SIZE)
	return Vector2i(round_x, round_y)

# Get the index in the array that cooresponds to the location (Assuming a perfect bit array)
func convertLocation(coordinates: Vector2i) -> int:
	# The offset in the array to get to the column that we care about
	return (coordinates.x / GLOB_SIZE) * (window_height / GLOB_SIZE) + (abs(coordinates.y) / GLOB_SIZE)

# Tests if there is a tar glob at the specified location
# Returns true iff there is NOT a tar glob at the queried location
func checkLocation(true_index: int) -> bool:
	# Get the relevant byte
	var tar_byte = tar_globs.decode_u8(true_index / 8)
	# Get the relevant bit
	if((tar_byte & (1 << (true_index % 8))) > 0):
		return false
	return true

# Store the fact that we've placed a tar glob at this location
func setLocation(true_index: int):
	var tar_byte = tar_globs.decode_u8(true_index / 8)
	# Set the relevant bit
	tar_globs.set(true_index / 8, (tar_byte | (1 << (true_index % 8))))

func resetTar():
	tar_globs.fill(0)


# Updates the value at a single pixel in the tar buffer
func _setBufferPixel(x: int, y: int, right_wall_dist: int, left_wall_dist: int) -> void:
	var r = 1.0 - float(right_wall_dist) / float(MAX_WALL_DIST)
	var g = 1.0 - float(left_wall_dist) / float(MAX_WALL_DIST)
	var old_tex = tar_buffer.get_pixel(x, y)
	tar_buffer.set_pixel(x, y, Color(max(r, old_tex.r), max(g, old_tex.g), 0, 1))

# Sets a glob for the given direction at the given position (in glob coordinates i.e. pixel/4)
func setBufferGlob(glob_position: Vector2i, wall_normal: Vector2):
	if wall_normal.x > 0:
		# Right-facing wall (red channel)
		for y in range(glob_position.y, glob_position.y + TarManager.GLOB_SIZE):
			for d in range(0, MAX_WALL_DIST):
				var x = glob_position.x - TarManager.GLOB_SIZE - 1 - d
				if x < 0: break

				_setBufferPixel(x, y, d, MAX_WALL_DIST)

		# Mark the buffer dirty for an update at the end of the frame
		_is_buffer_dirty = true

	elif wall_normal.x < 0:
		# Left-facing wall (green channel)
		for y in range(glob_position.y, glob_position.y + TarManager.GLOB_SIZE):
			for d in range(0, MAX_WALL_DIST):
				var x = glob_position.x + d
				if x >= tar_buffer.get_width(): break

				_setBufferPixel(x, y, MAX_WALL_DIST, d)

		# Mark the buffer dirty for an update at the end of the frame
		_is_buffer_dirty = true

# Commits the current tar buffer to the imagetexture, called after a batch of updates to the tar buffer is done
func _commitBuffer() -> void:
	tar_buffer_tex.update(tar_buffer)

func _process(_delta: float) -> void:
	# If the buffer is dirty, commit our updates to the image texture
	if _is_buffer_dirty:
		_commitBuffer()
		_is_buffer_dirty = false
