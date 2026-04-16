extends Node
@warning_ignore_start("integer_division")

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
