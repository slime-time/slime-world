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

// Instance uniforms (udpated per volume)
instance uniform vec2 fluid_rect_size = vec2(64, 16);               // Size of the rectangle we're drawing fluid on, in pixels
instance uniform int fluid_level = 16;                              // The fluid level, from 0 to 16 (# of rows from the bottom that have fluid)
instance uniform float fluid_velocity = 0.0;                        // The horizontal velocity of the fluid, in vibe units per second (+ is rightward)

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

// vec4 apply_refraction(vec4 color, vec2 pixel_coords, vec2 screen_pixel_coords) {

// }

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
    else COLOR = base_color; // Fluid pixel
}
