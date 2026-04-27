extends ColorRect
class_name TarLayer

# Max distance from the wall to write to the tar buffer for a given pixel
const MAX_WALL_DIST: int = 8

var tar_buffer: Image
var tar_buffer_tex: ImageTexture

var _is_buffer_dirty: bool = false

func _ready() -> void:
	# Set to full screen size
	size = get_viewport_rect().size

	# Initialize the tar buffer
	tar_buffer = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	tar_buffer.fill(Color(0, 0, 0, 0))
	tar_buffer_tex = ImageTexture.create_from_image(tar_buffer)

	# Set the shader parameters
	material = material.duplicate()
	material.set_shader_parameter("tar_buffer", tar_buffer_tex)

# Updates the value at a single pixel in the tar buffer
func _setPixel(x: int, y: int, right_wall_dist: int, left_wall_dist: int) -> void:
	# FIXME: min distances with existing values
	var r = 1.0 - float(right_wall_dist) / float(MAX_WALL_DIST)
	var g = 1.0 - float(left_wall_dist) / float(MAX_WALL_DIST)
	tar_buffer.set_pixel(x, y, Color(r, g, 0, 1))

# Sets a glob for the given direction at the given position (in glob coordinates i.e. pixel/4)
func setGlob(glob_position: Vector2i, wall_normal: Vector2):
	if wall_normal.x > 0:
		# Right-facing wall (red channel)
		for y in range(glob_position.y, glob_position.y + TarManager.GLOB_SIZE):
			for d in range(0, MAX_WALL_DIST):
				var x = glob_position.x - TarManager.GLOB_SIZE - 1 - d
				if x < 0: break

				_setPixel(x, y, d, MAX_WALL_DIST)

		# Mark the buffer dirty for an update at the end of the frame
		_is_buffer_dirty = true

	elif wall_normal.x < 0:
		# Left-facing wall (green channel)
		for y in range(glob_position.y, glob_position.y + TarManager.GLOB_SIZE):
			for d in range(0, MAX_WALL_DIST):
				var x = glob_position.x + d
				if x >= tar_buffer.get_width(): break

				_setPixel(x, y, MAX_WALL_DIST, d)

		# Mark the buffer dirty for an update at the end of the frame
		_is_buffer_dirty = true

func _process(_delta: float) -> void:
	# If the buffer is dirty, commit our updates to the image texture
	if _is_buffer_dirty:
		_commit()
		_is_buffer_dirty = false

# Commits the current tar buffer to the imagetexture, called after a batch of updates to the tar buffer is done
func _commit() -> void:
	tar_buffer_tex.update(tar_buffer)
