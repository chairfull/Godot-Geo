class_name UGeo extends RefCounted
# Utility scripts.

const RADIUS := 1.0
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
	var lat_rad := deg_to_rad(lat0)
	var x := deg_to_rad(lonlat.x) * radius * cos(lat_rad)  # meters east
	var y := deg_to_rad(lonlat.y) * radius                 # meters north
	return Vector2(x, y)

static func meters_to_lonlat(pos_m: Vector2, lat0: float = 0.0, radius: float = METERS_RADIUS) -> Vector2:
	# pos_m.x = meters east, pos_m.y = meters north
	var lat_deg = rad_to_deg(pos_m.y / radius)
	var lon_deg = rad_to_deg(pos_m.x / (radius * cos(deg_to_rad(lat0))))
	return Vector2(lon_deg, lat_deg)

static func ray_sphere_intersect(ray_position: Vector3, ray_normal: Vector3, sphere_position: Vector3, sphere_radius := 1.0) -> Vector3:
	var dir := ray_position - sphere_position
	var a := ray_normal.dot(ray_normal)
	var b := 2 * ray_normal.dot(dir)
	var c := dir.dot(dir) - sphere_radius * sphere_radius
	var disc := b*b - 4*a*c
	if disc < 0:
		return ray_position  # no intersection
	var sqrt_disc := sqrt(disc)
	var t0 := (-b - sqrt_disc) / (2*a)
	var t1 := (-b + sqrt_disc) / (2*a)
	var t = minf(t0, t1)
	if t < 0:
		t = maxf(t0, t1)  # behind ray?
		if t < 0:
			return ray_position
	return ray_position + ray_normal * t
