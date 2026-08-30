shader_type canvas_item;

instance uniform vec4 instance_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Default to white (no tint)

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    COLOR = texture_color * instance_color;
}
