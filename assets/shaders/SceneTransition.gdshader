shader_type canvas_item;

global uniform ivec2 SCREEN_SIZE_PIXELS;
global uniform float QUANTIZED_TIME = 0.0;

uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);      // Color to draw with
uniform float slope : hint_range(0.0, 10.0) = 1.0;                            // Slope of a line definining one corner of the wipe

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;           // Screen texture provided by Godot
uniform bool apply_dead_effect = false;                                       // Whether to apply the dead effect (desaturation + scanlines) to the background
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

    vec4 screen_color = vec4(0.0);
    if (apply_dead_effect) {
        // Apply fisheye (offset our UVs so its like tv bulge)
        vec2 centered_uv = screen_uv - vec2(0.5);
        float radius = length(centered_uv);
        float max_radius = length(vec2(0.5, 0.5));
        float distortion = 0.05;   // How strong the fisheye effect is
        float distorted_radius = radius + distortion * pow(radius / max_radius, 2.0);
        vec2 distorted_uv = (centered_uv / radius) * distorted_radius + vec2(0.5);
        screen_color = texture(screen_tex, distorted_uv);

        // Apply a desaturation
        float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

        // Deepen the scanlines and tie them to screen UV properly
        float scanline_depth = 0.1;
        float scanline = 1.0 - scanline_depth + scanline_depth * sin(screen_uv.y * float(SCREEN_SIZE_PIXELS.y) * 3.14159);

        // Add a slow vertical CRT roll
        float roll = 0.95 + 0.05 * sin(screen_uv.y * 5.0 - TIME * 5.0);

        // Darken corners for the CRT tube look
        float vignette = 1.0 - smoothstep(0.4, 1.5, radius);

        // Multiply it all together
        screen_color.rgb = mix(screen_color.rgb, vec3(gray), 0.5) * scanline * roll * vignette;
    }

    COLOR = screen_color;
    COLOR.rgb = mix(COLOR.rgb, transition_color.rgb, transition_color.a * alpha);
    COLOR.a = max(screen_color.a, transition_color.a * alpha);
}
