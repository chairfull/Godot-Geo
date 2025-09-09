shader_type spatial;
render_mode depth_draw_always, unshaded, cull_back;

void fragment() {
	DEPTH = clamp(FRAGCOORD.z + 0.005, 0.00, 0.99);
	ALBEDO = COLOR.rgb;
}