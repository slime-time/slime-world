shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.2;
uniform float edge_softness : hint_range(0.1, 8.0) = 1.0;
//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex_color = texture(TEXTURE, UV);
	float dist_x = 2.0 * abs(SCREEN_UV.x - 0.5); // dist from left/right edges
	float dist_y = 2.0 * abs(SCREEN_UV.y - 0.5); // dist from top/bottom edges
	
	float delta_x = 	pow(dist_x, edge_softness), delta_y = pow(dist_y, edge_softness);
	
	float adjust1 = clamp(delta_x + delta_y, 0.0, 1.0); 
	float adjust2 = clamp(max(delta_x, delta_y), 0.0, 1.0); 
	float adjust = (adjust1 + adjust2) / 2.0;

	COLOR = vec4(tex_color.rgb * (1.0-darkness * (0.5 + 0.5 * adjust)), tex_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
