@tool
class_name GeoJSONMesh extends MeshInstance3D

@export_file_path("*.json", "*.geojson") var file: String
@export_storage var colliders: Array[PackedVector2Array]
@export_tool_button("Regenerate") var toolbutton_regenerate := _update_mesh

@export var color := Color.WHITE
@export var outline_color := Color.WHITE
@export var outline_size := 4.0

func is_lonlat_inside(lonlat: Vector2) -> bool:
	for collider in colliders:
		if Geometry2D.is_point_in_polygon(lonlat, collider):
			return true
	return false

func _update_mesh():
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var features := GeoJSON.load_features(file)
	for feature in features:
		match feature.type:
			"Polygon", "LineString":
				_add_linestring(st, feature.coords)
				colliders.assign([feature.coords])
			"MultiPolygon", "MultiLineString":
				for poly in feature.coords:
					_add_polygon(st, poly)
				colliders.assign(feature.coords)
			_:
				push_warning("Unsupported type: %s" % feature.type)
	mesh = st.commit()
	
	var mat := ShaderMaterial.new()
	mat.shader = load("res://addons/geo/geojson_line_renderer_aa.gdshader")
	material_override = mat

func _add_polygon(st: SurfaceTool, rings: Array) -> void:
	if rings.is_empty():
		return
	var outer: PackedVector2Array = rings[0]
	if outer.size() < 3:
		return
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outer)
	if indices.is_empty():
		return
	for t in range(0, indices.size(), 3):
		st.add_vertex(GeoJSON.lonlat_to_vec3(outer[indices[t+2]]))
		st.add_vertex(GeoJSON.lonlat_to_vec3(outer[indices[t+1]]))
		st.add_vertex(GeoJSON.lonlat_to_vec3(outer[indices[t]]))

func _add_linestring(st: SurfaceTool, points: Array) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		var a: Vector3 = GeoJSON.lonlat_to_vec3(points[i])
		var b: Vector3 = GeoJSON.lonlat_to_vec3(points[i + 1])
		var seg := b - a
		if seg.length() == 0:
			continue
		var tangent := seg.normalized()
		st.set_uv(Vector2(-1, 0)); st.set_normal(tangent); st.add_vertex(a)
		st.set_uv(Vector2( 1, 0)); st.set_normal(tangent); st.add_vertex(a)
		st.set_uv(Vector2(-1, 0)); st.set_normal(tangent); st.add_vertex(b)
		# triangle 2
		st.set_uv(Vector2(-1, 0)); st.set_normal(tangent); st.add_vertex(b)
		st.set_uv(Vector2( 1, 0)); st.set_normal(tangent); st.add_vertex(a)
		st.set_uv(Vector2( 1, 0)); st.set_normal(tangent); st.add_vertex(b)
