shader_type canvas_item;

#include "res://assets/shaders/includes/noise.gdshaderinc"
#include "res://assets/shaders/includes/blending.gdshaderinc"

// Globals
global uniform ivec2 SCREEN_SIZE_PIXELS;

// Basic settings
group_uniforms BasicSettings;
uniform vec4 base_color: source_color = vec4(0.2, 0.4, 0.8, 0.8);   // The base color of the fluid, before applying flow texture or lighting
uniform vec4 outline_color: source_color = vec4(0.0);               // The color to use for the outline
uniform int framerate = 12;                                         // The framerate of the fluid animation (frames per second)

// Wave settings
group_uniforms Waves;
uniform vec2 wave_octave0 = vec2(0.8, 0.1);
uniform vec2 wave_octave1 = vec2(0.4, 0.3);
uniform vec2 wave_octave2 = vec2(0.2, 0.7);
uniform vec2 wave_envelope = vec2(0.05, 2.0);                       // Frequency and timescale of the wave envelope
uniform vec2 wave_envelope_range = vec2(0.35, 0.65);                // The range (min, max) to remap the wave envelope to before multiplying into displacement
uniform float wave_amplitude = 0.5;                                 // Overall amplitude factor applied to the premultiplied wave octaves
uniform float wave_timescale = 1.0;                                 // How quickly the wave animates over time, as a multiplier on top of fluid velocity
uniform float wave_row_offset = 0.2;                                // How much to offset the displacement wave by each row up

// Horizontal streak settings
group_uniforms Streaks;
uniform vec2 streak_noise_scale = vec2(0.1, 0.5);                     // Scale of the noise for horizontal streaks
uniform float streak_noise_timescale = 0.5;                           // How quickly to morph the noise for horizontal streaks
uniform float streak_scroll_speed = 16.0;                             // How fast the horizontal streaks should move downward
uniform int streak_blend : hint_blend_mode = 1;                       // Blend mode to use for horizontal streaks
uniform vec3 streak_color : source_color = vec3(1.0);                 // Color to blend in for horizontal streaks
uniform float streak_bias_low = 0.3;                                  // Where to start fading streaks from 0 to 1
uniform float streak_bias_high = 0.7;                                 // Where to stop fading streaks from 0 to 1
uniform float streak_steps = 3.0;                                     // Number of steps to posterize the streak effect into
uniform float streak_intensity = 0.5;                                 // Strength of the horizontal streak effect
group_uniforms Streaks2;
uniform vec2 streak2_noise_scale = vec2(0.1, 0.5);                     // Scale of the noise for horizontal streaks
uniform float streak2_noise_timescale = 0.5;                           // How quickly to morph the noise for horizontal streaks
uniform float streak2_scroll_speed = 16.0;                             // How fast the horizontal streaks should move downward
uniform int streak2_blend : hint_blend_mode = 1;                       // Blend mode to use for horizontal streaks
uniform vec3 streak2_color : source_color = vec3(1.0);                 // Color to blend in for horizontal streaks
uniform float streak2_bias_low = 0.3;                                  // Where to start fading streaks from 0 to 1
uniform float streak2_bias_high = 0.7;                                 // Where to stop fading streaks from 0 to 1
uniform float streak2_steps = 3.0;                                     // Number of steps to posterize the streak effect into
uniform float streak2_intensity = 0.5;                                 // Strength of the horizontal streak effect

// Refraction settings
group_uniforms Refraction;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;   // Screen texture provided by Godot
uniform float refract_strength = 0.8;                                 // Strength of the refraction effect (offset in pixels)
uniform float refract_frequency = 0.5;                                // Frequency of the vertical refraction waves
uniform float refract_timescale = 2.0;                                // Timescale for the refraction animation

// Instance uniforms (updated per volume)
instance uniform vec2 fluid_rect_size = vec2(64, 16);                 // Size of the rectangle we're drawing fluid on, in pixels
instance uniform int fluid_level = 16;                                // The fluid level, from 0 to 16 (# of rows from the bottom that have fluid)
instance uniform float fluid_velocity = 0.0;                          // The horizontal velocity of the fluid, in vibe units per second (+ is rightward)

// Instance uniforms don't support arrays, so we split flow extents into int vectors
// Distance each row up from the bottom extends to the left
instance uniform vec4 extents_left_0 = vec4(0);
instance uniform vec4 extents_left_4 = vec4(0);
instance uniform vec4 extents_left_8 = vec4(0);
instance uniform vec4 extents_left_12 = vec4(0);
// Distance each row up from the bottom extends to the right
instance uniform vec4 extents_right_0 = vec4(64);
instance uniform vec4 extents_right_4 = vec4(64);
instance uniform vec4 extents_right_8 = vec4(64);
instance uniform vec4 extents_right_12 = vec4(64);

// Gets the floored coordinates of the pixel we're drawing
vec2 get_pixel_coords(vec2 uv) {
    return floor((uv * vec2(1.0, -1.0) + vec2(0.0, 1.0)) * fluid_rect_size);
}

// Gets the floored UV coordinates of the pixel we're drawing
// We reinterpret such that v=0 is at the bottom and v=1 is the top
vec2 get_pixel_uv(vec2 uv) {
    return get_pixel_coords(uv) / fluid_rect_size;
}

// Checks whether the given pixel UV is within the fluid area (adjusted for max wave displacement + outline)
bool in_fluid_area(vec2 pixel_coords) {
  int row = int(pixel_coords.y);
  float max_wave_displacement = wave_octave0.x + wave_octave1.x + wave_octave2.x + 1.0;

  // Check if we're definitely OOB
  if (row < 0) return false;
  if (row >= fluid_level && float(row) > float(fluid_level) + max_wave_displacement) return false;

  // If we might be in the max displaced fluid area, check against the extents of a clamped row
  row = min(row, fluid_level - 1);

  if (row < 4) return extents_left_0[row] <= pixel_coords.x && pixel_coords.x <= extents_right_0[row];
  if (row < 8) return extents_left_4[row - 4] <= pixel_coords.x && pixel_coords.x <= extents_right_4[row - 4];
  if (row < 12) return extents_left_8[row - 8] <= pixel_coords.x && pixel_coords.x <= extents_right_8[row - 8];
  return extents_left_12[row - 12] <= pixel_coords.x && pixel_coords.x <= extents_right_12[row - 12];
}

// Gets the displacement height of the wave at the given pixel coordinates and time
float get_wave_displacement(vec2 pixel_coords, float qtime) {
    // Compute quantized wave sample points
    float wave_x = floor(pixel_coords.x + (pixel_coords.y * wave_row_offset));
    float x0 = wave_x - floor(qtime * fluid_velocity * wave_timescale);
    float x1 = wave_x - floor(qtime * fluid_velocity * wave_timescale);
    float x2 = wave_x - floor(qtime * fluid_velocity * wave_timescale);

    // Compute the actual displacement
    float raw_displacement = 0.0;
    raw_displacement += floor(wave_octave0.x * sin(wave_octave0.y * x0));
    raw_displacement += floor(wave_octave1.x * sin(wave_octave1.y * x1));
    raw_displacement += floor(wave_octave2.x * sin(wave_octave2.y * x2));
    raw_displacement = round(raw_displacement);

    // Compute the wave envelope (amplitude modulation by column)
    float envelope = sin(wave_x * wave_envelope.x - qtime * wave_envelope.y * wave_timescale);
    envelope = envelope * (wave_envelope_range.y - wave_envelope_range.x) / 2.0 + wave_envelope_range.x; // Remap from [-1, 1] to [range.x, range.y]

    // Get the overall displacement and quantize
    float displacement = round(raw_displacement * envelope * wave_amplitude);

    return displacement;
}

float get_fluid_height(vec2 pixel_coords, float qtime) {
    return float(fluid_level) + get_wave_displacement(vec2(pixel_coords.x, float(fluid_level)), qtime);
}

vec4 apply_refraction(vec4 color, vec2 pixel_coords, vec2 screen_pixel_coords, float qtime) {
    // Horizontal refraction part
    float wave = sin(qtime * refract_timescale + round(screen_pixel_coords.y + 0.5) * refract_frequency);
    vec2 pixel_offset = vec2(float(wave * refract_strength * color.a), 0.0); // Include a factor of alpha to fade smoothly at the falloff

    // Include the displacement in the refraction offset
    pixel_offset.x += get_wave_displacement(pixel_coords, qtime);

    // Quantize the refraction to whole pixels
    pixel_offset = round(pixel_offset + 0.5);

    float pixel_size = 1.0 / float(SCREEN_SIZE_PIXELS.x);
    vec2 snapped_screen_uv = (screen_pixel_coords) / vec2(SCREEN_SIZE_PIXELS);
    vec2 refract_uv = snapped_screen_uv + pixel_offset * pixel_size;
    vec4 refract_color = texture(screen_tex, refract_uv);

    // Blend in the refracted color
    color = blend(BLEND_SCREEN, refract_color, color, color.a);
    color.a = 1.0; // We render the refracted background, so don't allow the original background to show through
    return color;
}

void fragment() {
    vec2 screen_pixel_coords = floor(SCREEN_UV * vec2(SCREEN_SIZE_PIXELS));   // Quantized screen coordinates of the pixel we're drawing
    vec2 pixel_coords = get_pixel_coords(UV);                                 // Pixel coordinates of the pixel we're drawing
    vec2 pixel_uv = get_pixel_uv(UV);                                         // UV coordinates of the pixel we're drawing, with v=0 at the bottom and v=1 at the top
    float qtime = round(TIME * float(framerate)) / float(framerate);          // Time quantized to animation framerate

    // If outside the fluid area, don't draw anything
    if (!in_fluid_area(pixel_coords)) discard;

    // If above the fluid height (including waves) and beyond the outline, don't draw anything
    float fluid_height = get_fluid_height(pixel_coords, qtime);
    if (pixel_coords.y > fluid_height) discard; // Empty pixel above the fluid and waves

    bool is_outline = pixel_coords.y >= fluid_height;
    if (is_outline) COLOR = outline_color; // Outline pixel
    else {
        // Fluid pixel
        COLOR = base_color;

        // Mix in streaks
        if (streak_intensity > 0.0) {
            float displacement = get_wave_displacement(pixel_coords, qtime);
            vec2 streak_noise_coords = (screen_pixel_coords + vec2(-qtime * streak_scroll_speed * fluid_velocity * fluid_velocity, round(displacement / 2.0))) * streak_noise_scale / 10.0;
            // vec2 streak_noise_coords = vec2(float(col) + , round(displacement / 2.0) floor(pixel_y) - qtime * streak_scroll_speed) * streak_noise_scale;
            float streak_noise = smoothstep(streak_bias_low, streak_bias_high, snoise(vec3(streak_noise_coords, streak_noise_timescale * qtime)));
            float streak_factor = round(streak_noise * streak_steps) / streak_steps;
            COLOR = blend(streak_blend, COLOR, vec4(streak_color, COLOR.a), streak_factor * streak_intensity);
        }
        if (streak2_intensity > 0.0) {
            float displacement = get_wave_displacement(pixel_coords, qtime);
            vec2 streak2_noise_coords = (screen_pixel_coords * 2.0 + vec2(-qtime * streak2_scroll_speed * fluid_velocity * fluid_velocity, round(displacement / 2.0))) * streak2_noise_scale / 10.0;
            // vec2 streak2_noise_coords = vec2(float(col) + , round(displacement / 2.0) floor(pixel_y) - qtime * streak2_scroll_speed) * streak2_noise_scale;
            float streak2_noise = smoothstep(streak2_bias_low, streak2_bias_high, snoise(vec3(streak2_noise_coords, streak2_noise_timescale * qtime)));
            float streak2_factor = round(streak2_noise * streak2_steps) / streak2_steps;
            COLOR = blend(streak2_blend, COLOR, vec4(streak2_color, COLOR.a), streak2_factor * streak2_intensity);
        }

        // Apply refraction to the fluid color
        COLOR = apply_refraction(COLOR, pixel_coords, screen_pixel_coords, qtime);
    }
}
