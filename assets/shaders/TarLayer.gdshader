shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

global uniform ivec2 SCREEN_SIZE_PIXELS;
global uniform float QUANTIZED_TIME = 0.0;

uniform vec3 tar_base_color: source_color;   // Base color of the tar, with alpha controlling opacity

// Buffer storing information on tar pixels
// Red channel stores right-facing walls, with 1.0 at the wall decreasing to 1/8 at a distance of 8 pixels
// Green channel stores this for left-facing walls
// Blue, if used, stores this for up-facing "walls" (i.e. the ground)
// This is only set for pixels away from the normal, as such:
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 |
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 | -> (wall normal)
//    -8 -7 -6 -5 -4 -3 -2 -1 -0 |
uniform sampler2D tar_buffer : filter_nearest;

vec4 getTar(vec2 screen_pixel_coords) {
    return texelFetch(tar_buffer, ivec2(screen_pixel_coords), 0);
}

void fragment() {
    vec2 screen_pixel_coords = floor(SCREEN_UV * vec2(SCREEN_SIZE_PIXELS));   // Quantized screen coordinates of the pixel we're drawing
    vec2 screen_pixel_uv = screen_pixel_coords / vec2(SCREEN_SIZE_PIXELS);    // UV coordinates of the pixel we're drawing, with v=0 at the bottom and v=1 at the top

    // Get the tar buffer value for this pixel
    COLOR = getTar(screen_pixel_coords);

    // COLOR.xy = screen_pixel_uv;
}
