shader_type canvas_item;
// Falling rain streaks, slanted, drawn over scene art. Cheap: no textures.

uniform vec4 tint : source_color = vec4(0.65, 0.78, 0.76, 1.0);
uniform float intensity = 0.32;
uniform float speed = 1.4;
uniform float columns = 26.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	uv.x += uv.y * 0.18;
	float cx = uv.x * columns;
	float col = floor(cx);
	float fx = fract(cx);
	float h = hash(vec2(col, 3.0));
	float len = 0.10 + 0.22 * h;
	float y = fract(uv.y * (0.8 + h * 0.7) - TIME * speed * (0.5 + h * 0.8) + h * 7.0);
	float streak = smoothstep(0.0, 0.015, y) * (1.0 - smoothstep(0.015, len, y));
	float line = 1.0 - smoothstep(0.0, 0.07, abs(fx - 0.5));
	float on = step(0.45, hash(vec2(col, 9.0)));
	COLOR = vec4(tint.rgb, streak * line * on * intensity);
}
