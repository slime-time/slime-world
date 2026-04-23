shader_type canvas_item;

// Buffer storing information on tar pixels
// Red channel stores right-facing walls, with 255 at the wall decreasing to a distance of 8 pixels (255-7 at the 8th pixel away)
// Green channel stores this for left-facing walls
// Blue, if used, stores this for up-facing "walls" (i.e. the ground)
// This is only set for pixels away from the normal, as such:
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 |
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 | -> (wall normal)
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 |
uniform isampler2D tar_buffer : source_color, filter_nearest;

void fragment() {
    COLOR = texture(tar_buffer, UV);
}
