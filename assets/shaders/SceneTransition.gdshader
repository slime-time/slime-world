shader_type canvas_item;

global uniform ivec2 SCREEN_SIZE_PIXELS;
global uniform float QUANTIZED_TIME = 0.0;

uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);      // Color to draw with
uniform float slope : hint_range(0.0, 10.0) = 1.0;                            // Slope of a line definining one corner of the wipe

uniform float transition_progress : hint_range(0.0, 1.0) = 0.0;               // 0.0 is fully black; 1.0 is fully transparent

void fragment() {
    vec2 screen_pixel_coords = floor(SCREEN_UV * vec2(SCREEN_SIZE_PIXELS));   // Quantized screen coordinates of the pixel we're drawing
    vec2 screen_pixel_uv = screen_pixel_coords / vec2(SCREEN_SIZE_PIXELS);    // UV coordinates of the pixel we're drawing
    vec2 screen_uv = SCREEN_UV;

    vec2 transition_uv = screen_uv;

    // Just do casework for the quadrants whatever dude
    float alpha = 0.0;
    if (transition_uv.x < 0.5 && transition_uv.y < 0.5) {
        // Top left quadrant
        float intercept_start = 0.5 + 0.5 * slope;
        float intercept_end = 0.0;

        float intercept = mix(intercept_start, intercept_end, transition_progress);
        float line_y = -slope * transition_uv.x + intercept;

        if (transition_uv.y < line_y) {
            alpha = 1.0;
        }
    } else if (transition_uv.x >= 0.5 && transition_uv.y < 0.5) {
        // Top right quadrant
        float intercept_start = 0.5 - 0.5 * slope;
        float intercept_end = -slope;

        float intercept = mix(intercept_start, intercept_end, transition_progress);
        float line_y = slope * transition_uv.x + intercept;

        if (transition_uv.y < line_y) {
            alpha = 1.0;
        }
    } else if (transition_uv.x < 0.5 && transition_uv.y >= 0.5) {
        // Bottom left quadrant
        float intercept_start = 0.5 - 0.5 * slope;
        float intercept_end = 1.0;

        float intercept = mix(intercept_start, intercept_end, transition_progress);
        float line_y = slope * transition_uv.x + intercept;

        if (transition_uv.y > line_y) {
            alpha = 1.0;
        }
    } else {
        // Bottom right quadrant
        float intercept_start = 0.5 + 0.5 * slope;
        float intercept_end = 1.0 + slope;

        float intercept = mix(intercept_start, intercept_end, transition_progress);
        float line_y = -slope * transition_uv.x + intercept;

        if (transition_uv.y > line_y) {
            alpha = 1.0;
        }
    }

    COLOR = vec4(transition_color.rgb, transition_color.a * alpha);
}
