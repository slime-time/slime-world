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

const int BLEND_MULTIPLY = 0;
const int BLEND_SCREEN = 1;
const int BLEND_DARKEN = 2;
const int BLEND_LIGHTEN = 3;
const int BLEND_DIFFERENCE = 4;
const int BLEND_EXCLUSION = 5;
const int BLEND_OVERLAY = 6;
const int BLEND_HARD_LIGHT = 7;
const int BLEND_SOFT_LIGHT = 8;
const int BLEND_COLOR_DODGE = 9;
const int BLEND_LINEAR_DODGE = 10;
const int BLEND_COLOR_BURN = 11;
const int BLEND_LINEAR_BURN = 12;

vec3 blend(int MODE, vec3 base3, vec3 over3, float factor) {
    vec4 base = vec4(base3, 1.0);
    vec4 over = vec4(over3, 1.0);
    switch (MODE) {
        case BLEND_MULTIPLY: return mix(base, multiply(base, over), factor).rgb;
        case BLEND_SCREEN: return mix(base, screen(base, over), factor).rgb;
        case BLEND_DARKEN: return mix(base, darken(base, over), factor).rgb;
        case BLEND_LIGHTEN: return mix(base, lighten(base, over), factor).rgb;
        case BLEND_DIFFERENCE: return mix(base, difference(base, over), factor).rgb;
        case BLEND_EXCLUSION: return mix(base, exclusion(base, over), factor).rgb;
        case BLEND_OVERLAY: return mix(base, overlay(base, over), factor).rgb;
        case BLEND_HARD_LIGHT: return mix(base, hard_light(base, over), factor).rgb;
        case BLEND_SOFT_LIGHT: return mix(base, soft_light(base, over), factor).rgb;
        case BLEND_COLOR_DODGE: return mix(base, color_dodge(base, over), factor).rgb;
        case BLEND_LINEAR_DODGE: return mix(base, linear_dodge(base, over), factor).rgb;
        case BLEND_COLOR_BURN: return mix(base, color_burn(base, over), factor).rgb;
        case BLEND_LINEAR_BURN: return mix(base, linear_burn(base, over), factor).rgb;
        default: return base.rgb;
    }
}

vec4 blend(int MODE, vec4 base, vec4 over, float factor) {
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

#define hint_blend_mode hint_enum(  \
    "MULTIPLY",                     \
    "SCREEN",                       \
    "DARKEN",                       \
    "LIGHTEN",                      \
    "DIFFERENCE",                   \
    "EXCLUSION",                    \
    "OVERLAY",                      \
    "HARD_LIGHT",                   \
    "SOFT_LIGHT",                   \
    "COLOR_DODGE",                  \
    "LINEAR_DODGE",                 \
    "COLOR_BURN",                   \
    "LINEAR_BURN"                   \
)
