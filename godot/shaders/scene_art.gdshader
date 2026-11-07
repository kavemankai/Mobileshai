shader_type canvas_item;
// Scene art. The TextureRect stretches the texture over its whole rect (STRETCH_SCALE) and this shader does
// the "cover" crop itself, so it can also drift the camera (zoom and pan) without moving the node.
// Also: rounded corners, a vignette, and a "remote voice" look (phone, recording, intercom):
// desaturated, scanlines and a little noise.

uniform float tex_aspect = 1.0;      // texture width / height
uniform vec2 rect_size = vec2(540.0, 400.0);
uniform float radius = 14.0;
uniform float focus_y : hint_range(0.0, 1.0) = 0.35;  // which band of a tall image to keep
uniform float zoom = 1.0;
uniform vec2 pan = vec2(0.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.45;
uniform float remote_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dim : hint_range(0.0, 1.0) = 0.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float rounded(vec2 p) {
	vec2 q = abs(p - rect_size * 0.5) - (rect_size * 0.5 - vec2(radius));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	return 1.0 - smoothstep(-1.0, 1.0, d);
}

vec2 cover_uv(vec2 uv) {
	float rect_aspect = rect_size.x / rect_size.y;
	vec2 s = vec2(1.0);
	if (rect_aspect > tex_aspect) {
		s.y = tex_aspect / rect_aspect;
	} else {
		s.x = rect_aspect / tex_aspect;
	}
	vec2 centre = vec2(0.5, mix(s.y * 0.5, 1.0 - s.y * 0.5, focus_y));
	vec2 p = centre + (uv - 0.5) * s / zoom + pan * s;
	return clamp(p, vec2(0.001), vec2(0.999));
}

void fragment() {
	vec4 c = texture(TEXTURE, cover_uv(UV));
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 mono = vec3(g) * vec3(0.82, 1.0, 0.94);
	float scan = 0.9 + 0.1 * sin(local.y * 1.6 + TIME * 5.0);
	float n = fract(sin(dot(local * 0.37 + floor(TIME * 24.0), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 remote = mono * scan + (n - 0.5) * 0.07;
	vec3 col = mix(c.rgb, remote, remote_amount);
	vec2 uv = local / rect_size;
	float v = smoothstep(0.35, 0.95, distance(uv, vec2(0.5)) * 1.45);
	col *= 1.0 - v * vignette;
	col *= 1.0 - dim;
	COLOR = vec4(col, c.a * rounded(local));
}
