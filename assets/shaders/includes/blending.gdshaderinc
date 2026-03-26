// Blend mode math from https://godotshaders.com/snippet/blending-modes/
// with modifications for easier usage

vec4 multiply(vec4 base, vec4 blend) {
	return base * blend;
}

vec4 screen(vec4 base, vec4 blend) {
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec4 darken(vec4 base, vec4 blend) { return min(base, blend); }
vec4 lighten(vec4 base, vec4 blend) { return max(base, blend); }

vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}

vec4 exclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

vec4 hard_light(vec4 base, vec4 blend) {
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

vec4 soft_light(vec4 base, vec4 blend) {
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
               sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

vec4 color_dodge(vec4 base, vec4 blend) { return base / (1.0 - blend); }
vec4 linear_dodge(vec4 base, vec4 blend) { return base + blend; }
vec4 color_burn(vec4 base, vec4 blend) { return 1.0 - (1.0 - base) / blend; }
vec4 linear_burn (vec4 base, vec4 blend) { return base + blend - 1.0; }

const uint BLEND_MULTIPLY = 0u;
const uint BLEND_SCREEN = 1u;
const uint BLEND_DARKEN = 2u;
const uint BLEND_LIGHTEN = 3u;
const uint BLEND_DIFFERENCE = 4u;
const uint BLEND_EXCLUSION = 5u;
const uint BLEND_OVERLAY = 6u;
const uint BLEND_HARD_LIGHT = 7u;
const uint BLEND_SOFT_LIGHT = 8u;
const uint BLEND_COLOR_DODGE = 9u;
const uint BLEND_LINEAR_DODGE = 10u;
const uint BLEND_COLOR_BURN = 11u;
const uint BLEND_LINEAR_BURN = 12u;

vec4 blend(uint MODE, vec4 base, vec4 over, float factor) {
    switch (MODE) {
        case BLEND_MULTIPLY: return mix(base, multiply(base, over), factor);
        case BLEND_SCREEN: return mix(base, screen(base, over), factor);
        case BLEND_DARKEN: return mix(base, darken(base, over), factor);
        case BLEND_LIGHTEN: return mix(base, lighten(base, over), factor);
        case BLEND_DIFFERENCE: return mix(base, difference(base, over), factor);
        case BLEND_EXCLUSION: return mix(base, exclusion(base, over), factor);
        case BLEND_OVERLAY: return mix(base, overlay(base, over), factor);
        case BLEND_HARD_LIGHT: return mix(base, hard_light(base, over), factor);
        case BLEND_SOFT_LIGHT: return mix(base, soft_light(base, over), factor);
        case BLEND_COLOR_DODGE: return mix(base, color_dodge(base, over), factor);
        case BLEND_LINEAR_DODGE: return mix(base, linear_dodge(base, over), factor);
        case BLEND_COLOR_BURN: return mix(base, color_burn(base, over), factor);
        case BLEND_LINEAR_BURN: return mix(base, linear_burn(base, over), factor);
        default: return base;
    }
}
