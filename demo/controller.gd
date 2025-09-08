@tool
extends Node3D

const RADIUS := 1.0
const MIN_ZOOM := RADIUS + .005
const MAX_ZOOM := 5.0

@onready var globe: Node3D = $globe
@onready var camera: Camera3D = $camera
@onready var cursor: Node3D = %cursor
var rotating := false
var goal_zoom := 1.0: set=set_goal_zoom
var goal_rotation := Vector3.ZERO
var _cursor_pos := Vector3.ZERO
var _last_cursor_pos := Vector3.ZERO

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	var lonlat := GeoJSON.vec3_to_lonlat(_cursor_pos * globe.global_basis)
	var hovered: Node = null
	for node: GeoJSONMesh in get_tree().get_nodes_in_group(&"GENERATED"):
		if node.is_lonlat_inside(lonlat):
			hovered = node
			break
	
	var last_rotation := globe.rotation
	var last_zoom := camera.global_position.z
	camera.global_position.z = lerpf(camera.global_position.z, goal_zoom, 10.0 * delta)
	globe.rotation.x = lerp_angle(globe.rotation.x, goal_rotation.x, 10.0 * delta)
	globe.rotation.y = lerp_angle(globe.rotation.y, goal_rotation.y, 10.0 * delta)
	cursor.scale = Vector3.ONE * pow(goal_zoom, 4.0) * .01

	if (last_rotation - globe.rotation).length() > .0001 or (absf(last_zoom - camera.global_position.z) > .0001):
		_update_marker_visibility()

func set_goal_zoom(z: float):
	goal_zoom = clampf(z, MIN_ZOOM, MAX_ZOOM)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			pass
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			goal_zoom -= 0.005 * goal_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			goal_zoom += 0.005 * goal_zoom
	
	elif event is InputEventMouseMotion:
		var ray_origin := camera.global_transform.origin
		var ray_dir := camera.project_ray_normal(event.position)
		var hit_point := ray_sphere_intersect(ray_origin, ray_dir, globe.global_position, RADIUS)
		if hit_point:
			_last_cursor_pos = _cursor_pos
			_cursor_pos = hit_point
			cursor.global_position = hit_point
		
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT and rotating:
			if _cursor_pos and _last_cursor_pos:
				var v0 = (_last_cursor_pos - globe.global_position).normalized()
				var v1 = (_cursor_pos - globe.global_position).normalized()
				var axis = v0.cross(v1)
				var axis_len = axis.length()
				if axis_len > 1e-6:
					axis = axis / axis_len
					var angle := acos(clampf(v0.dot(v1), -1.0, 1.0))
					var delta_quat = Quaternion(axis, angle)
					goal_rotation += delta_quat.get_euler()
		
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			var delta: Vector2 = event.relative
			var pan_speed := 0.01
			camera.translate(-camera.transform.basis.x * delta.x * pan_speed)
			camera.translate(camera.transform.basis.y * delta.y * pan_speed)

func ray_sphere_intersect(ray_start: Vector3, ray_normal: Vector3, sphere_pos: Vector3, sphere_radius: float) -> Vector3:
	var dir := ray_start - sphere_pos
	var a := ray_normal.dot(ray_normal)
	var b := 2 * ray_normal.dot(dir)
	var c := dir.dot(dir) - sphere_radius * sphere_radius
	var disc := b*b - 4*a*c
	if disc < 0:
		return ray_start  # no intersection
	var sqrt_disc := sqrt(disc)
	var t0 := (-b - sqrt_disc) / (2*a)
	var t1 := (-b + sqrt_disc) / (2*a)
	var t = minf(t0, t1)
	if t < 0:
		t = maxf(t0, t1)  # behind ray?
		if t < 0:
			return ray_start
	return ray_start + ray_normal * t

func _update_marker_visibility():
	var globe_position := globe.global_position
	var camera_forward := camera.global_transform.basis.z.normalized()
	for marker in get_tree().get_nodes_in_group(&"globe_marker"):
		if not marker is GlobeMarker: continue
		var was_in_front: bool = marker.get_meta(&"was_in_front", false)
		var to_marker = (marker.global_position - globe_position).normalized()
		var is_in_front := camera_forward.dot(to_marker) >= 0.7
		if was_in_front != is_in_front:
			marker.set_meta(&"was_in_front", is_in_front)
			if not marker.icon: continue
			if was_in_front:
				marker.icon.globe_front_exited.emit()
			else:
				marker.icon.globe_front_entered.emit()
		
		# Update marker 2d position.
		if not marker.icon: continue
		marker.icon.position = camera.unproject_position(marker.global_position)
