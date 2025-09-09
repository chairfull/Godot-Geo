@tool
class_name GeoJSONMesh extends MeshInstance3D

@export_file_path("*.json", "*.geojson", "*.geo.json") var file: String
@export_storage var colliders: Dictionary[PackedVector2Array, Dictionary]
@export_tool_button("Regenerate") var toolbutton_regenerate := _update_mesh

@export var color := Color.WHITE
@export var outline_color := Color.WHITE
@export var outline_size := 4.0
var vertex_count := 0.0

func get_feature_at_lonlat(lonlat: Vector2) -> Dictionary:
	for collider in colliders:
		if Geometry2D.is_point_in_polygon(lonlat, collider):
			return colliders[collider]
	return {}

func is_lonlat_inside(lonlat: Vector2) -> bool:
	for collider in colliders:
		if Geometry2D.is_point_in_polygon(lonlat, collider):
			return true
	return false

func _update_mesh():
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	vertex_count = 0
	colliders = {}
	
	var features := load_features(file)
	for feature in features:
		match feature.type:
			"LineString":
				_add_linestring(st, feature.coords)
			"MultiLineString":
				for line in feature.coords:
					_add_linestring(st, line)
					#colliders.append(line)
			"Polygon":
				_add_polygon(st, feature.coords)
				for poly in feature.coords:
					colliders[poly] = feature
			"MultiPolygon":
				for poly in feature.coords:
					_add_polygon(st, poly)
					for subpoly in poly:
						colliders[subpoly] = feature
			_:
				push_warning("Unsupported type: %s" % feature.type)
				continue
		feature.erase("coords")
	mesh = st.commit()
	print(vertex_count)
	
	if not material_override:
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
	var clr := Color.DEEP_SKY_BLUE
	clr.ok_hsl_h = randf_range(-PI, PI)
	for t in range(0, indices.size(), 3):
		st.set_color(clr)
		st.add_vertex(UGeo.lonlat_to_vec3(outer[indices[t+2]]))
		st.set_color(clr)
		st.add_vertex(UGeo.lonlat_to_vec3(outer[indices[t+1]]))
		st.set_color(clr)
		st.add_vertex(UGeo.lonlat_to_vec3(outer[indices[t]]))
		vertex_count += 3

func _add_linestring(st: SurfaceTool, points: Array) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		var a: Vector3 = UGeo.lonlat_to_vec3(points[i])
		var b: Vector3 = UGeo.lonlat_to_vec3(points[i + 1])
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

static func load_features(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Can't open " + path)
		return []
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("No dictionary " + path)
		return []
	
	if not "features" in data:
		if "type" in data and data.type == "Feature":
			data = { "features": [data] }
		else:
			push_error("No features "+ path)
			return []
	
	var features: Array[Dictionary]
	for feature_data in data.features:
		var geom: Dictionary = feature_data.geometry
		var geom_type: String = geom.type
		var feature := { type=geom_type }
		match geom_type:
			"Polygon":
				feature.coords = _multiple_polygons(geom.coordinates)
			"LineString":
				feature.coords = _polygon(geom.coordinates)
			"MultiLineString":
				var lines: Array
				for line in geom.coordinates:
					lines.append(_polygon(line))
				feature.coords = lines
			"MultiPolygon":
				var polys: Array
				for poly in geom.coordinates:
					polys.append(_multiple_polygons(poly))
				feature.coords = polys
			_:
				push_error("Type not implemented: %s." % geom_type)
				continue
		for key in feature_data:
			if not key in ["coordinates", "type", "geometry"]:
				feature[key] = feature_data[key]
		features.append(feature)
	return features

static func _multiple_polygons(coords: Array) -> Array[PackedVector2Array]:
	var rings: Array[PackedVector2Array]
	for ring in coords:
		rings.append(_polygon(ring))
	return rings

static func _polygon(coords: Array) -> PackedVector2Array:
	var result: PackedVector2Array
	for point in coords:
		result.append(Vector2(point[0], point[1]))
	return result
