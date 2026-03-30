shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

// Globals
global uniform ivec2 SCREEN_SIZE_PIXELS;

// Basic settings
group_uniforms BasicSettings;
uniform sampler2D fluid_tex : filter_nearest, repeat_enable;  // The fluid texture to sample
uniform float base_opacity = 0.8;                             // The base opacity of the fluid, before applying flow distance falloff
uniform int flow_extent = 256;                                // The extent of the flow texture in pixels, for calculating pixel UVs
uniform int framerate = 12;                                    // The framerate of the fluid animation (frames per second)
uniform int frame_count = 16;                                 // The total number of frames in the texture
uniform float outline_threshold = 0.0;                        // Max value of max(r,g,b) to be considered outline (no refraction)
uniform float flow_falloff_top = 8.0;     // How many pixels from the top to start fading out
uniform float flow_falloff_bottom = 8.0;  // How many pixels from the hit point to start fading out

// Displacement settings
group_uniforms HorizontalDisplacement;
// Each octave defines {amplitude, frequency} of a sine wave
// Uniform arrays can't have default values so we just hardcode the number of octaves... godot sucks sometimes
uniform vec2 displacement_octave0 = vec2(0.3, 0.1);
uniform vec2 displacement_octave1 = vec2(0.1, 0.3);
uniform vec2 displacement_octave2 = vec2(0.05, 0.7);
uniform float displacement_timescale = 32.0;          // How fast the displacement wave should move downward
uniform float displacement_column_offset = 0.2;       // How much to offset the displacement wave by each column

// Refraction settings
group_uniforms Refraction;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;   // Screen texture provided by Godot
uniform float refract_strength = 0.8;                                 // Strength of the refraction effect (offset in pixels)
uniform float refract_frequency = 0.5;                                // Frequency of the vertical refraction waves
uniform float refract_timescale = 2.0;                               // Timescale for the refraction animation

// Foam settings
group_uniforms Foam;
uniform vec3 foam_color = vec3(1.0, 1.0, 1.0);  // The color to use for the foam effect
uniform float foam_noise_scale = 120.0;         // Noise sampling scale for foam
uniform float foam_timescale = 5.0;             // Foam noise timescale
uniform float foam_distance = 6.0;              // How many pixels (Δy) around the flow end are affected by foam
uniform float foam_steps = 4.0;                 // Minimum noise value to show foam
uniform float foam_intensity = 2.5;             // Intensity of the foam effect, from 0 to 1

// Voronoi (ice shard) settings
group_uniforms Voronoi;
uniform bool do_voronoi = false;                                  // Whether to apply the voronoi effect at all, for performance reasons
uniform vec2 voronoi_cell_size = vec2(8.0, 8.0);                  // Size of a voronoi grid cell in pixels
uniform float voronoi_refraction_strength = 1.5;                  // Strength of the effect voronoi cell values have on refraction offset
uniform int voronoi_color_blend_mode : hint_blend_mode = 1;       // Blending mode to use for mixing voronoi cell colors into the fluid color
uniform vec3 voronoi_color_factors = vec3(1.0, 1.0, 1.0);         // Per-channel factors to premultiply the voronoi cell color
uniform float voronoi_color_mix = 0.5;                            // Strength of the effect voronoi cell values have on color, for each channel
uniform float voronoi_lightness_strength = 0.5;                   // Strength of the effect avg(r,g,b) of the voronoi cell color has on lightness of the final color
uniform vec4 voronoi_boundary_color = vec4(1.0, 1.0, 1.0, 0.5);   // Color to blend in for voronoi cell boundaries, where A is the strength of the boundary effect
uniform float voronoi_boundary_threshold = 0.1;                   // Max value of the voronoi boundary distance to be considered a boundary pixel
uniform float voronoi_boundary_exponent = 2.0;                    // Exponent to apply to the boundary effect strength, to make it more or less focused on the actual boundary line
uniform float voronoi_boundary_steps = 3.0;

instance uniform float flow_start = 0.0;            // How far down flow starts, in pixels from the top of the texture

// Instance uniforms don't support arrays, so we split flow distances into int vectors
// These are the distances each flow column extends down to
instance uniform ivec4 flow_distances_0 = ivec4(256);
instance uniform ivec4 flow_distances_4 = ivec4(256);
instance uniform ivec4 flow_distances_8 = ivec4(256);
instance uniform ivec4 flow_distances_12 = ivec4(256);

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

// Gets the horizontal displacement for the given position
float get_displacement(int col, float pixel_y, float qtime) {
    float displacement = 0.0;
    float wave_y = round(pixel_y + 0.5) + float(col) * displacement_column_offset - qtime * displacement_timescale;
    displacement += displacement_octave0.x * sin(displacement_octave0.y * wave_y);
    displacement += displacement_octave1.x * sin(displacement_octave1.y * wave_y);
    displacement += displacement_octave2.x * sin(displacement_octave2.y * wave_y);
    displacement = round(displacement); // Quantize displacement

    return displacement;
}

// Gets the UV coordinates for sampling a certain pixel column and y coordinate
// col is 0-16 if a regular flow part, or -1/-2/16/17 for border parts
vec4 get_part_color(int col, float pixel_y, float dist, vec2 screen_uv, float qtime) {
    if (pixel_y > dist + flow_falloff_bottom) {
        // This pixel is outside the flow area, so draw nothing
        return vec4(0.0);
    }

    int frame_index = int(TIME * float(framerate)) % frame_count;

    float frame_v = float(frame_index) / float(frame_count);
    float local_v = fract(pixel_y / 16.0) / float(frame_count);

    // Compute displacement for the current pixel
    float displacement = get_displacement(col, pixel_y, qtime);

    // Calculate the sampling UV
    vec2 tex_uv = vec2((16.5 + float(col) + displacement) / 48.0, frame_v + local_v);

    vec4 tex_color = texture(fluid_tex, tex_uv);
    tex_color.a *= base_opacity;

    // Handle fade out at the top
    if (pixel_y <= flow_start + min(flow_start, flow_falloff_top)) {
        tex_color.a *= round(pixel_y - flow_start) / min(flow_start, flow_falloff_top);
    }

    // Handle fade out at the bottom
    // We count dist as the start of falloff and dist+falloff as the end
    if (pixel_y >= dist) {
        tex_color.a *= (dist + flow_falloff_bottom - pixel_y) / float(flow_falloff_bottom);
    }

    // Apply foam effect near the bottom of the flow
    if (abs(pixel_y - dist) <= foam_distance) {
        vec2 pixel_uv = floor(screen_uv * vec2(SCREEN_SIZE_PIXELS)) / vec2(SCREEN_SIZE_PIXELS);
        vec3 noise_uv = vec3(pixel_uv * foam_noise_scale + vec2(0.0, qtime * foam_timescale), 0.0);
        float foam_noise_raw = snoise(noise_uv);
        float foam_amount = min(1.0, (1.0 - pow(1.0 - foam_noise_raw, 2.0)) * pow(1.0 - floor(abs(pixel_y - dist)) / foam_distance, 1.5) * foam_intensity);

        float foam_stepped = round(foam_amount * foam_steps) / foam_steps; // Step the foam amount to create more distinct patches
        float foam_alpha = (0.5 + (tex_color.a / 2.0)) * clamp((round(pixel_y) - round(flow_start)) / flow_falloff_bottom, 0.0, 1.0);
        vec4 foam_blend = vec4(foam_color, foam_alpha);
        tex_color = blend(BLEND_SCREEN, tex_color, foam_blend, foam_stepped);
    }

    return tex_color;
}

void fragment() {
    // Get the column index (0 to 15) and flow distance for this column
    int col = int(UV.x * 20.0) - 2; // 16 columns of flow; -2, -1, 16, and 17 are for borders
    float dist = float(get_flow_distance(col));

    // Get the pixel y coordinate we're drawing
    float pixel_y = UV.y * float(flow_extent);

    // Time quantized to animation framerate
    float qtime = round(TIME * float(framerate)) / float(framerate);

    // If this pixel is not in the flow area, draw nothing
    if (col < 0 || col > 15 || pixel_y < flow_start || pixel_y > dist + flow_falloff_bottom) {
        // ...unless we are a border part for neighboring flow
        // I am just hardcoding the four cases here because it's easier honestly I know it sucks don't @ me
        if (pixel_y <= get_flow_distance_offset(col - 1, flow_falloff_bottom)) {
            // We are part of the right border of the left neighbor's flow
            COLOR = get_part_color(16, pixel_y, float(get_flow_distance(col - 1)), SCREEN_UV, qtime);
        } else if (pixel_y <= get_flow_distance_offset(col - 2, flow_falloff_bottom)) {
            // We are a further right border part of the left neighbor's flow
            COLOR = get_part_color(17, pixel_y, float(get_flow_distance(col - 2)), SCREEN_UV, qtime);
        } else if (pixel_y <= get_flow_distance_offset(col + 1, flow_falloff_bottom)) {
            // We are part of the left border of the right neighbor's flow
            COLOR = get_part_color(-1, pixel_y, float(get_flow_distance(col + 1)), SCREEN_UV, qtime);
        } else if (pixel_y <= get_flow_distance_offset(col + 2, flow_falloff_bottom)) {
            // We are a further left border part of the right neighbor's flow
            COLOR = get_part_color(-2, pixel_y, float(get_flow_distance(col + 2)), SCREEN_UV, qtime);
        } else {
            // We are not part of any flow, so draw nothing
            COLOR.a = 0.0;
        }
    } else {
        // We're in the flow area for this column, so draw the regular flow part
        COLOR = get_part_color(col, pixel_y, dist, SCREEN_UV, qtime);
    }

    // Determine whether we're in an outline pixel
    bool is_outline = max(COLOR.r, max(COLOR.g, COLOR.b)) <= outline_threshold;

    vec4 voronoi_sample;
    if (do_voronoi && !is_outline) {
        vec2 pixel_uv = floor(SCREEN_UV * vec2(SCREEN_SIZE_PIXELS) - vec2(0.0, qtime * displacement_timescale)) / vec2(SCREEN_SIZE_PIXELS);
        voronoi_sample = voronoi(vec2(SCREEN_SIZE_PIXELS) / voronoi_cell_size, pixel_uv);

        // Mix the voronoi cell value into the color
        COLOR.rgb = blend(voronoi_color_blend_mode, COLOR.rgb, voronoi_sample.rgb * voronoi_color_factors, voronoi_color_mix);
        float voronoi_lightness = (voronoi_sample.r + voronoi_sample.g + voronoi_sample.b) / 3.0;
        COLOR.rgb = blend(voronoi_color_blend_mode, COLOR.rgb, vec3(voronoi_lightness), voronoi_lightness_strength);

        // Apply the voronoi boundary
        if (voronoi_sample.a <= voronoi_boundary_threshold) {
            vec3 boundary_blend = voronoi_boundary_color.rgb;
            float boundary_mix = pow((1.0 - voronoi_sample.a / voronoi_boundary_threshold), voronoi_boundary_exponent);
            boundary_mix = round(boundary_mix * voronoi_boundary_steps) / voronoi_boundary_steps; // Step the boundary mix to create more distinct borders
            COLOR.rgb = blend(voronoi_color_blend_mode, COLOR.rgb, boundary_blend, boundary_mix * voronoi_boundary_color.a);
        }
    }

    // Apply screen refraction
    if (COLOR.a > 0.0 && !is_outline) {
        float wave = sin(TIME * refract_timescale + round(pixel_y + 0.5) * refract_frequency);
        vec2 pixel_offset = vec2(float(wave * refract_strength * COLOR.a), 0.0); // Include a factor of alpha to fade smoothly at the falloff

        // Include the displacement in the refraction offset
        pixel_offset.x += get_displacement(col, pixel_y, qtime);

        // Include the voronoi displacement if enabled
        if (do_voronoi) {
            // Center the voronoi value around 0 and apply strength
            pixel_offset += (voronoi_sample.rg - vec2(0.5)) * voronoi_refraction_strength;
        }

        // Quantize the refraction to whole pixels
        pixel_offset = round(pixel_offset);

        float pixel_size = 1.0 / float(SCREEN_SIZE_PIXELS.x);
        vec2 snapped_screen_uv = (floor(SCREEN_UV * vec2(SCREEN_SIZE_PIXELS)) + 0.5) / vec2(SCREEN_SIZE_PIXELS);
        vec2 refract_uv = snapped_screen_uv + pixel_offset * pixel_size;
        vec4 refract_color = texture(screen_tex, refract_uv);

        // Blend in the refracted color
        COLOR = blend(BLEND_SCREEN, refract_color, COLOR, COLOR.a);
        COLOR.a = 1.0; // We render the refracted background, so don't allow the original background to show through
    }
}
