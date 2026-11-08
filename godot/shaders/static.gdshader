shader_type canvas_item;
// TV static for the match-3 board: clearing it reveals the picture underneath.

uniform float intensity : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = floor(FRAGCOORD.xy / 2.0);
	float t = floor(TIME * 18.0);
	float n = hash(p + t * 7.13);
	float scan = 0.82 + 0.18 * sin(FRAGCOORD.y * 1.3 + TIME * 9.0);
	vec3 col = vec3(n * 0.62 * scan) + vec3(0.02, 0.05, 0.07);
	COLOR = vec4(col, 0.95 * intensity);
}
