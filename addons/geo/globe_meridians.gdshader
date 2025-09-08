shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

// Grid color
uniform vec4 line_color : source_color = vec4(1.0,1.0,1.0,0.05);

// Grid parameters
uniform int num_meridians : hint_range(2, 128) = 128;
uniform int num_latitudes : hint_range(2, 64) = 64;
uniform float line_width = 0.0001; // radians

// LOD based on camera distance
uniform float zoom = 1.0; // camera distance or zoom factor
uniform float fine_zoom = 0.5;
uniform float coarse_zoom = 2.0;

// Pass vertex position to fragment shader
varying vec3 v_pos;

void vertex() {
    v_pos = VERTEX; // object space
}

void fragment() {
    vec3 p = normalize(v_pos);

    // Spherical coordinates
    float lat = asin(clamp(p.y, -1.0, 1.0)); // -π/2..π/2
    float lon = atan(p.z, p.x);               // -π..π

    // Grid steps
    float lat_step = PI / float(num_latitudes);
    float lon_step = 2.0 * PI / float(num_meridians);

    // Distance to nearest latitude/meridian
    float lat_dist = min(mod(lat + 0.5*PI, lat_step), lat_step - mod(lat + 0.5*PI, lat_step));
    float lon_dist = min(mod(lon + PI, lon_step), lon_step - mod(lon + PI, lon_step));

    float d = min(lat_dist, lon_dist);

    // Anti-aliasing width based on derivatives
    float width = line_width + fwidth(d);

    // LOD fade
    float lod_t = clamp((coarse_zoom - zoom) / (coarse_zoom - fine_zoom), 0.0, 1.0);

    // Smooth alpha for anti-aliasing
    float alpha = smoothstep(width, 0.0, d) * lod_t;

    if (alpha < 0.01) {
        discard; // optional: skip almost transparent fragments for speed
    }

    ALBEDO = line_color.rgb;
    ALPHA = alpha * line_color.a;
}
