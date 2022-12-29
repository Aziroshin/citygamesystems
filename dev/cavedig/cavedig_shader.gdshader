shader_type spatial;
uniform vec3 color;

void fragment() {
	ALBEDO = vec3(color);
}