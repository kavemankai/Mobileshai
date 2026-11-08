shader_type canvas_item;
// Portraits: the cut-out ones need nothing; the first-pass rectangular crops fade out along their left edge.

uniform float edge_fade : hint_range(0.0, 1.0) = 0.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform vec2 rect_size = vec2(300.0, 300.0);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float fx = local.x / rect_size.x;
	float fade = mix(1.0, smoothstep(0.0, 0.25, fx), edge_fade);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, vec3(g), desaturate), c.a * fade);
}
