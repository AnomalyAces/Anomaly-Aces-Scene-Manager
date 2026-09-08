shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0, 0.1);
uniform float tile_size: hint_range(0.0, 128.0, 0.1) = 16;

void fragment() {
	
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 num_of_tiles = viewport_size / tile_size;
	vec2 position_in_square = UV * num_of_tiles;
	vec2 frac = fract(position_in_square);
	vec2 dir = frac - 0.5;
	
	if(abs(dir.x) + abs(dir.y) + UV.x +UV.y >= progress * 4.0){
		discard;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
