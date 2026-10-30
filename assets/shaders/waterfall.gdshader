// Cascade : traînées d'eau défilant vers le bas.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 color : source_color = vec4(0.55, 0.88, 1.0, 0.75);
uniform float speed = 1.6;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	float s = noise(vec2(uv.x * 22.0, uv.y * 4.0 - TIME * speed * 3.0));
	float s2 = noise(vec2(uv.x * 9.0 + 3.0, uv.y * 2.0 - TIME * speed * 2.0));
	float streak = smoothstep(0.35, 0.95, s * 0.6 + s2 * 0.4);
	float edge = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);
	ALBEDO = color.rgb + streak * 0.35;
	ALPHA = color.a * (0.45 + 0.55 * streak) * edge;
}
