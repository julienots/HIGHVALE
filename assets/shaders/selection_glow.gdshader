// Surbrillance du bâtiment sélectionné (appliquée en material_overlay).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never;

uniform vec4 glow : source_color = vec4(1.0, 0.85, 0.3, 1.0);

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float pulse = 0.55 + 0.45 * sin(TIME * 5.0);
	ALBEDO = glow.rgb * (0.12 + fres * 0.8) * pulse;
}
