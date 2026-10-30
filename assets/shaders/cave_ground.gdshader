// Sol de la caverne : roche procédurale, mousse et dallage de la zone constructible.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 rock_light : source_color = vec4(0.26, 0.24, 0.33, 1.0);
uniform vec4 rock_dark : source_color = vec4(0.10, 0.09, 0.14, 1.0);
uniform vec4 floor_color : source_color = vec4(0.42, 0.34, 0.27, 1.0);
uniform vec4 moss_color : source_color = vec4(0.16, 0.42, 0.33, 1.0);
// Zone constructible en coordonnées monde : (min x, min z, max x, max z).
uniform vec4 buildable = vec4(3.0, 3.0, 37.0, 37.0);

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float n = fbm(p * 0.35);
	vec2 q = max(buildable.xy - p, p - buildable.zw);
	float outside = max(q.x, q.y);
	float inside = 1.0 - smoothstep(-0.6, 0.8, outside);

	// Dallage irrégulier de la cité.
	vec2 sp = p / 2.0 + vec2(0.0, step(1.0, mod(floor(p.x / 2.0), 2.0)) * 0.5);
	vec2 cell = floor(sp);
	vec2 f = fract(sp);
	float h = hash(cell);
	float joint = smoothstep(0.0, 0.07, f.x) * smoothstep(0.0, 0.07, f.y) * smoothstep(0.0, 0.07, 1.0 - f.x) * smoothstep(0.0, 0.07, 1.0 - f.y);
	vec3 floor_c = floor_color.rgb * (0.82 + 0.3 * h) * (0.62 + 0.38 * joint) * (0.85 + 0.3 * n);

	vec3 rock = mix(rock_dark.rgb, rock_light.rgb, n);
	float moss = smoothstep(0.52, 0.72, fbm(p * 0.16 + 7.0));
	rock = mix(rock, moss_color.rgb, moss * 0.55);
	// Bordure de pierres claires autour de la zone constructible.
	float rim = smoothstep(0.9, 0.2, abs(outside - 0.3));
	vec3 c = mix(rock, floor_c, inside);
	c = mix(c, vec3(0.62, 0.56, 0.48) * (0.8 + 0.3 * n), rim * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.92;
}
