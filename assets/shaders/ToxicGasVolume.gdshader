shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

global uniform ivec2 SCREEN_SIZE_PIXELS;
global uniform float QUANTIZED_TIME = 0.0;

uniform vec4 base_color : source_color = vec4(0.5, 1.0, 0.5, 0.5);    // Base color for the gas with alpha
uniform int blend_mode : hint_blend_mode = 1;                         // Blending mode for the gas
uniform float posterize_steps = 6.0;                                  // Number of steps to posterize the gas alpha into
uniform float intensity = 1.0;                                        // Intensity multiplier for the gas blend
uniform float falloff_pixels = 8.0;                                   // How many pixels from the edge to start fading out the gas

uniform vec2 noise_scale = vec2(1.0, 1.0);                            // Scale of the noise pattern in xyz
uniform vec3 noise_time_factors = vec3(0.0, 0.0, 1.0);                // How much to offset by time in each dimension
uniform float noise_bias_low = 0.3;                                   // Where to start fading noise from 0 to 1
uniform float noise_bias_high = 0.7;                                  // Where to stop fading noise from 0 to 1

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;   // Screen texture provided by Godot
instance uniform vec2 area_size = vec2(32, 32);                       // Size of the area in pixels

// Gets the floored coordinates of the pixel we're drawing
vec2 get_pixel_coords(vec2 uv) {
    return floor((uv * vec2(1.0, -1.0) + vec2(0.0, 1.0)) * area_size);
}

// Gets the floored UV coordinates of the pixel we're drawing
// We reinterpret such that v=0 is at the bottom and v=1 is the top
vec2 get_pixel_uv(vec2 uv) {
    return get_pixel_coords(uv) / area_size;
}

void fragment() {
    vec2 pixel_coords = get_pixel_coords(UV);   // Pixel coordinates of the pixel we're drawing
    vec2 pixel_uv = get_pixel_uv(UV);           // UV coordinates of the pixel we're drawing, with v=0 at the bottom and v=1 at the top

    vec2 inverse_edge_distance = vec2(
        1.0 - min(min(pixel_coords.x, area_size.x - 1.0 - pixel_coords.x), falloff_pixels) / falloff_pixels,
        1.0 - min(min(pixel_coords.y, area_size.y - 1.0 - pixel_coords.y), falloff_pixels) / falloff_pixels);
    float edge_falloff = max(0.0, 1.0 - length(inverse_edge_distance));

    vec3 noise_uv = vec3(pixel_uv * noise_scale, 0.0) + (noise_time_factors * QUANTIZED_TIME);
    float noise_value = smoothstep(noise_bias_low, noise_bias_high, snoise(noise_uv));

    vec4 screen_color = texture(screen_tex, SCREEN_UV);
    vec4 gas_color = vec4(base_color.rgb, base_color.a * noise_value * edge_falloff);        // Modulate alpha by noise value
    COLOR.rgb = blend(blend_mode, screen_color.rgb, gas_color.rgb, floor(gas_color.a * posterize_steps) / posterize_steps * intensity);
    COLOR.a = 1.0;
}
