class_name GeoJSON extends RefCounted

const METERS_RADIUS := 6371000.0

static func lonlat_to_vec3(lonlat: Vector2) -> Vector3:
	var lon := deg_to_rad(lonlat.x)
	var lat := deg_to_rad(lonlat.y)
	var x := cos(lat) * cos(lon)
	var y := sin(lat)
	var z := cos(lat) * sin(lon)
	return Vector3(x, y, -z)

static func vec3_to_lonlat(pos: Vector3) -> Vector2:
	var r := float(pos.length())
	var lat := asin(pos.y / r)
	var lon := atan2(-pos.z, pos.x)
	return Vector2(rad_to_deg(lon), rad_to_deg(lat))

static func lonlat_to_meters(lonlat: Vector2, lat0: float = 0.0, radius: float = METERS_RADIUS) -> Vector2:
	# lat0 = reference latitude in degrees (for longitude scaling)
	var lat_rad = deg_to_rad(lat0)
	var x = deg_to_rad(lonlat.x) * radius * cos(lat_rad)  # meters east
	var y = deg_to_rad(lonlat.y) * radius                 # meters north
	return Vector2(x, y)

static func meters_to_lonlat(pos_m: Vector2, lat0: float = 0.0, radius: float = METERS_RADIUS) -> Vector2:
	# pos_m.x = meters east, pos_m.y = meters north
	var lat_deg = rad_to_deg(pos_m.y / radius)
	var lon_deg = rad_to_deg(pos_m.x / (radius * cos(deg_to_rad(lat0))))
	return Vector2(lon_deg, lat_deg)


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
			"Polygon", "LineString":
				feature.coords = _polygon(geom.coordinates)
				features.append(feature)
			"MultiPolygon", "MultiLineString":
				var polys: Array
				for poly in geom.coordinates:
					polys.append(_polygons(poly))
				feature.coords = polys
				features.append(feature)
			_:
				push_error("Type not implemented: %s." % geom_type)
	return features

static func _polygons(coords: Array) -> Array[PackedVector2Array]:
	var rings: Array[PackedVector2Array]
	for ring in coords:
		rings.append(_polygon(ring))
	return rings

static func _polygon(coords: Array) -> PackedVector2Array:
	var result: PackedVector2Array
	for point in coords:
		result.append(Vector2(point[0], point[1]))
	return result
