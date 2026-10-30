// Eau souterraine animée.
shader_type spatial;
render_mode blend_mix, specular_schlick_ggx, depth_draw_always;

uniform vec4 deep : source_color = vec4(0.02, 0.16, 0.34, 0.92);
uniform vec4 shallow : source_color = vec4(0.12, 0.62, 0.85, 1.0);
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wpos.x * 1.3 + TIME * 1.5) * 0.03 + cos(wpos.z * 1.1 + TIME * 1.2) * 0.03;
}

void fragment() {
	float w = sin(wpos.x * 2.1 + TIME * 1.7) * cos(wpos.z * 2.4 - TIME * 1.3);
	float w2 = sin((wpos.x + wpos.z) * 3.7 - TIME * 2.1);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 c = mix(deep.rgb, shallow.rgb, 0.45 + 0.35 * w);
	ALBEDO = c;
	ALPHA = mix(deep.a, 1.0, fres);
	ROUGHNESS = 0.06;
	SPECULAR = 0.9;
	float sparkle = smoothstep(0.82, 1.0, w * 0.5 + w2 * 0.5);
	EMISSION = shallow.rgb * 0.08 * (0.6 + 0.4 * w) + vec3(0.7, 0.95, 1.0) * sparkle * 0.35;
}
