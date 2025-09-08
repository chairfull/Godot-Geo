shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float line_width_px : hint_range(0.5,200.0) = 2.0;
uniform vec2 viewport_size = vec2(1920.0,1080.0);

void vertex() {
	// view-space
	vec3 view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 clip_pos = PROJECTION_MATRIX * vec4(view_pos, 1.0);

	// tangent in view-space (from NORMAL supplied per-vertex)
	vec3 tangent_view = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// camera direction in view-space
	vec3 cam_dir = normalize(-view_pos);

	// perpendicular (screen-space) direction in view-space
	vec3 side_view = cross(cam_dir, tangent_view);
	if (length(side_view) < 1e-6) {
		side_view = cross(vec3(0.0, 1.0, 0.0), tangent_view); // fallback
	}
	side_view = normalize(side_view);

	// project a unit step along side_view to get pixel direction
	vec4 clip_side = PROJECTION_MATRIX * vec4(view_pos + side_view, 1.0);

	// NDC -> pixels
	vec2 ndc_center = clip_pos.xy / clip_pos.w;
	vec2 ndc_side   = clip_side.xy / clip_side.w;
	vec2 px_center  = (ndc_center * 0.5 + 0.5) * viewport_size;
	vec2 px_side    = (ndc_side   * 0.5 + 0.5) * viewport_size;

	vec2 dir_px = px_side - px_center;
	float len_px = max(length(dir_px), 1e-6);
	vec2 dir_px_n = dir_px / len_px;

	// half-width, signed by UV.x
	float half_w = line_width_px * 0.5;
	vec2 offset_px = dir_px_n * half_w * UV.x;

	// back to NDC, then to clip-space
	vec2 offset_ndc = (offset_px / viewport_size) * 2.0;
	clip_pos.xy += offset_ndc * clip_pos.w;
	POSITION = clip_pos;
}

void fragment() {
	ALBEDO = vec3(1.0); // white; change as needed
}
