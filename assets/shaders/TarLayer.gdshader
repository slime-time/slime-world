shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

global uniform ivec2 SCREEN_SIZE_PIXELS;
global uniform float QUANTIZED_TIME = 0.0;

uniform vec3 tar_base_color: source_color;      // Base color of the tar, with alpha controlling opacity
uniform float posterize_steps = 6.0;            // Number of steps to posterize the gas alpha into
uniform int blend_mode: hint_blend_mode = 1;    // Blending mode for the tar

uniform vec2 noise_scale = vec2(1.0, 1.0);      // Scale of the noise pattern in xyz
uniform float noise_bias_low = 0.3;             // Where to start fading noise from 0 to 1
uniform float noise_bias_high = 0.7;            // Where to stop fading noise from 0 to 1
uniform float intensity = 1.0;                  // Overall intensity multiplier for the tar effect

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

    // Get the original texture color and tar buffer value for this pixel
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 tar = getTar(screen_pixel_coords);

    if (tex_color.a == 0.0) {
        // If there is no tile here, don't draw anything
        discard;
    }

    vec3 noise_uvw = vec3(screen_pixel_uv * noise_scale, 0.0);
    float noise_value = snoise(noise_uvw);

    float tar_level = pow(max(tar.r, tar.g), 1.0);
    float smoothed_amount = smoothstep(noise_bias_low, noise_bias_high, noise_value * tar_level);
    float blend_amount = floor(posterize_steps * smoothed_amount) / posterize_steps;

    COLOR.rgb = blend(blend_mode, tex_color.rgb, tar_base_color, blend_amount * intensity);
    COLOR.a = tex_color.a;

    // COLOR.xy = screen_pixel_uv;
}
