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
    if (col < 4) return flow_distances_0[col];
    if (col < 8) return flow_distances_4[col - 4];
    if (col < 12) return flow_distances_8[col - 8];
    return flow_distances_12[col - 12];
}

void fragment() {
    // Get the column index (0 to 15) and flow distance for this column
    int col = clamp(int(UV.x * 16.0), 0, 15);
    float dist = min(float(get_flow_distance(col)), flow_end);

    // Get the pixel y coordinate we're drawing
    float pixel_y = UV.y * float(flow_extent);

    // If this pixel is below the flow distance, draw nothing
    if (pixel_y < flow_start || pixel_y > dist) {
        COLOR.a = 0.0;
    } else {
        // Sample the water texture
        // The texture is assumed to be a column of frame_count frames, each of which is 16x16 pixels
        // We do some scaling to tile the appropriate frame down the flow distance
        float frame_v = float(frame_index) / float(frame_count);
        float local_v = fract(pixel_y / 16.0) / float(frame_count);
        vec2 tex_uv = vec2((1.0 + UV.x) / 3.0, frame_v + local_v);
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

        // Set the final color
        COLOR = tex_color;
    }
}
