shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

// Globals
global uniform ivec2 SCREEN_SIZE_PIXELS;

// Basic settings
uniform sampler2D fluid_tex : filter_nearest, repeat_enable;  // The fluid texture to sample
uniform float base_opacity = 0.8;                             // The base opacity of the fluid, before applying flow distance falloff
uniform int flow_extent = 256;                                // The extent of the flow texture in pixels, for calculating pixel UVs
uniform int frame_count = 16;                                 // The total number of frames in the texture
uniform float outline_threshold = 0.0;                        // Max value of max(r,g,b) to be considered outline (no refraction)

// Instance uniforms don't support arrays, so we split flow distances into int vectors
// These are the distances each flow column extends down to
instance uniform ivec4 flow_distances_0;
instance uniform ivec4 flow_distances_4;
instance uniform ivec4 flow_distances_8;
instance uniform ivec4 flow_distances_12;

// Extra VFX settings
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;   // Screen texture provided by Godot
uniform float refract_strength = 1.0;                                 // Strength of the refraction effect (offset in pixels)
uniform float refract_frequency = 0.7;                                // Frequency of the vertical refraction waves
uniform float refract_timescale = 2.0;                               // Timescale for the refraction animation

uniform vec3 highlight_color = vec3(1.0, 1.0, 1.0);  // The color to use for the highlight noise effect
uniform float highlight_noise_scale = 20.0;          // Noise sampling scale for highlight noise
uniform float highlight_timescale = 0.6;             // Highlight noise timescale
uniform float highlight_intensity = 0.4;             // Intensity of the highlight noise effect, from 0 to 1

instance uniform int frame_index = 0;               // The current animation frame index (0 to 16)
instance uniform float flow_start = 0.0;            // How far down flow starts, in pixels from the top of the texture
instance uniform float flow_falloff_top = 16.0;     // How many pixels from the top to start fading out
instance uniform float flow_falloff_bottom = 16.0;  // How many pixels from the hit point to start fading out

// Gets the flow distance for a given column index (0 to 15), or 0 if out of bounds
int get_flow_distance(int col) {
    if (col < 0 || col > 15) return 0;

    if (col < 4) return flow_distances_0[col];
    if (col < 8) return flow_distances_4[col - 4];
    if (col < 12) return flow_distances_8[col - 8];
    return flow_distances_12[col - 12];
}

float get_flow_distance_offset(int col, float offset) {
    if (col < 0 || col > 15) return 0.0;
    return float(get_flow_distance(col)) + offset;
}

// Gets the UV coordinates for sampling a certain pixel column and y coordinate
// col is 0-16 if a regular flow part, or -1/-2/16/17 for border parts
vec4 get_part_color(int col, float pixel_y, float dist) {
    if (pixel_y > dist + flow_falloff_bottom) {
        // This pixel is outside the flow area, so draw nothing
        return vec4(0.0);
    }

    float frame_v = float(frame_index) / float(frame_count);
    float local_v = fract(pixel_y / 16.0) / float(frame_count);
    vec2 tex_uv = vec2(float(16 + col) / 48.0, frame_v + local_v);

    vec4 tex_color = texture(fluid_tex, tex_uv);
    tex_color.a *= base_opacity;

    // Handle fade out at the top
    if (pixel_y <= flow_start + flow_falloff_top) {
        tex_color.a *= (pixel_y - flow_start) / float(flow_falloff_top);
    }

    // Handle fade out at the bottom
    // We count dist as the start of falloff and dist+falloff as the end
    if (pixel_y >= dist) {
        tex_color.a *= (dist + flow_falloff_bottom - pixel_y) / float(flow_falloff_bottom);
    }

    return tex_color;
}

void fragment() {
    // Get the column index (0 to 15) and flow distance for this column
    int col = int(UV.x * 20.0) - 2; // 16 columns of flow; -2, -1, 16, and 17 are for borders
    float dist = float(get_flow_distance(col));

    // Get the pixel y coordinate we're drawing
    float pixel_y = UV.y * float(flow_extent);

    // If this pixel is not in the flow area, draw nothing
    if (col < 0 || col > 15 || pixel_y < flow_start || pixel_y > dist + flow_falloff_bottom) {
        // ...unless we are a border part for neighboring flow
        // I am just hardcoding the four cases here because it's easier honestly I know it sucks don't @ me
        if (pixel_y <= get_flow_distance_offset(col - 1, flow_falloff_bottom)) {
            // We are part of the right border of the left neighbor's flow
            COLOR = get_part_color(16, pixel_y, float(get_flow_distance(col - 1)));
        } else if (pixel_y <= get_flow_distance_offset(col - 2, flow_falloff_bottom)) {
            // We are a further right border part of the left neighbor's flow
            COLOR = get_part_color(17, pixel_y, float(get_flow_distance(col - 2)));
        } else if (pixel_y <= get_flow_distance_offset(col + 1, flow_falloff_bottom)) {
            // We are part of the left border of the right neighbor's flow
            COLOR = get_part_color(-1, pixel_y, float(get_flow_distance(col + 1)));
        } else if (pixel_y <= get_flow_distance_offset(col + 2, flow_falloff_bottom)) {
            // We are a further left border part of the right neighbor's flow
            COLOR = get_part_color(-2, pixel_y, float(get_flow_distance(col + 2)));
        } else {
            // We are not part of any flow, so draw nothing
            COLOR.a = 0.0;
        }
    } else {
        // We're in the flow area for this column, so draw the regular flow part
        COLOR = get_part_color(col, pixel_y, dist);
    }

    // Determine whether we're in an outline pixel
    bool is_outline = max(COLOR.r, max(COLOR.g, COLOR.b)) <= outline_threshold;

    // Apply screen refraction
    if (COLOR.a > 0.0 && !is_outline) {
        float wave = sin(TIME * refract_timescale + floor(pixel_y) * refract_frequency);
        float pixel_offset = round(wave * refract_strength * COLOR.a); // Include a factor of alpha to fade smoothly at the falloff

        float pixel_size = 1.0 / float(SCREEN_SIZE_PIXELS.x);
        vec2 refract_uv = SCREEN_UV + vec2(pixel_offset * pixel_size, 0.0);
        vec4 refract_color = texture(screen_tex, refract_uv);

        // Blend in the refracted color
        // COLOR = blend(BLEND_OVERLAY, refract_color, COLOR, COLOR.a);
        COLOR = blend(BLEND_SCREEN, refract_color, COLOR, COLOR.a);
        COLOR.a = 1.0; // We render the refracted background, so don't allow the original background to show through
    }

    // // Apply the highlight noise effect on top of the base color
    // if (highlight_intensity > 0.0) {
    //     float highlight_noise_raw = snoise(vec3(SCREEN_UV * highlight_noise_scale, TIME * highlight_timescale));
    //     float highlight_noise = pow(highlight_noise_raw, 0.5);
    //     COLOR = blend(BLEND_SOFT_LIGHT, COLOR, vec4(highlight_color, COLOR.a), highlight_noise * highlight_intensity);
    // }
}
