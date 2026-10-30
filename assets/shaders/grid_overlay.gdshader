// Quadrillage affiché pendant la construction ou le déplacement d'un bâtiment.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 line_color : source_color = vec4(1.0, 0.95, 0.7, 0.35);
uniform float opacity = 1.0;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = abs(fract(wpos.xz) - 0.5);
	float d = 0.5 - max(g.x, g.y);
	float line = 1.0 - smoothstep(0.0, 0.03, d);
	ALBEDO = line_color.rgb;
	ALPHA = line * line_color.a * opacity;
}
