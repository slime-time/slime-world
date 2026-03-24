shader_type canvas_item;


uniform sampler2D fluid_tex : filter_nearest, repeat_enable;  // The fluid texture to sample
uniform float base_opacity = 1.0;                             // The base opacity of the fluid, before applying flow distance falloff
uniform int flow_extent = 256;                                // The extent of the flow texture in pixels, for calculating pixel UVs
uniform int frame_count = 16;                                 // The total number of frames in the texture
instance uniform int frame_index = 0;                         // The current animation frame index (0 to 16)

instance uniform float flow_start = 0.0;            // How far down flow starts, in pixels from the top of the texture
instance uniform float flow_end = 256.0;            // How far down flow can go, in pixels from the top of the texture
instance uniform float flow_falloff_top = 16.0;     // How many pixels from the top to start fading out
instance uniform float flow_falloff_bottom = 16.0;  // How many pixels from the hit point to start fading out

// Instance uniforms don't support arrays, so we split flow distances into int vectors
instance uniform ivec4 flow_distances_0;
instance uniform ivec4 flow_distances_4;
instance uniform ivec4 flow_distances_8;
instance uniform ivec4 flow_distances_12;

int get_flow_distance(int col) {
    if (col < 0 || col > 15) return 0;

    if (col < 4) return flow_distances_0[col];
    if (col < 8) return flow_distances_4[col - 4];
    if (col < 12) return flow_distances_8[col - 8];
    return flow_distances_12[col - 12];
}

// Gets the UV coordinates for sampling a certain pixel column and y coordinate
// col is 0-16 if a regular flow part, or -1/-2/16/17 for border parts
vec4 get_part_color(int col, float pixel_y, float dist) {
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
    if (pixel_y >= dist - flow_falloff_bottom) {
        tex_color.a *= (dist - pixel_y) / float(flow_falloff_bottom);
    }

    return tex_color;
}

void fragment() {
    // Get the column index (0 to 15) and flow distance for this column
    int col = int(UV.x * 20.0) - 2; // 16 columns of flow; -2, -1, 16, and 17 are for borders
    float dist = min(float(get_flow_distance(col)), flow_end);

    // Get the pixel y coordinate we're drawing
    float pixel_y = UV.y * float(flow_extent);

    // If this pixel is not in the flow area, draw nothing
    if (col < 0 || col > 15 || pixel_y < flow_start || pixel_y > dist) {
        // ...unless we are a border part for neighboring flow
        // I am just hardcoding the four cases here because it's easier honestly I know it sucks don't @ me
        if (pixel_y <= float(get_flow_distance(col - 1))) {
            // We are part of the right border of the left neighbor's flow
            COLOR = get_part_color(16, pixel_y, float(get_flow_distance(col - 1)));
        } else if (pixel_y <= float(get_flow_distance(col - 2 ))) {
            // We are a further right border part of the left neighbor's flow
            COLOR = get_part_color(17, pixel_y, float(get_flow_distance(col - 2)));
        } else if (pixel_y <= float(get_flow_distance(col + 1))) {
            // We are part of the left border of the right neighbor's flow
            COLOR = get_part_color(-1, pixel_y, float(get_flow_distance(col + 1)));
        } else if (pixel_y <= float(get_flow_distance(col + 2))) {
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
}
