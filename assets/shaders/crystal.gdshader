// Cristal lumineux : émission pulsée + reflet de Fresnel. Phase propre à chaque instance.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.15, 0.55, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.45, 0.85, 1.0, 1.0);
uniform float glow_strength = 1.6;
uniform float pulse_speed = 1.3;

varying float phase;

void vertex() {
	// Phase dérivée de la position monde : une vague lumineuse parcourt la caverne,
	// y compris lorsque les cristaux sont fusionnés en un seul maillage.
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	phase = sin(wp.x * 0.45) * 2.0 + cos(wp.z * 0.38) * 2.0;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed + phase);
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.12;
	METALLIC = 0.1;
	SPECULAR = 0.9;
	EMISSION = glow_color.rgb * glow_strength * (0.3 + fres) * pulse;
}
