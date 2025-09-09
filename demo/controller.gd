@tool
extends Node

const RADIUS := 1.0
const MIN_ZOOM := RADIUS + .005
const MAX_ZOOM := 5.0

@onready var cursor: Node3D = %cursor
@onready var globe: Node3D = $globe
@onready var camera: Camera3D = $camera
@onready var goal_zoom := camera.global_position.z: set=set_goal_zoom
var goal_rotation := Quaternion.IDENTITY

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return

	var last_rotation := globe.rotation
	var last_zoom := camera.global_position.z
	camera.global_position.z = lerpf(camera.global_position.z, goal_zoom, 10.0 * delta)
	var current_quat := globe.transform.basis.get_rotation_quaternion()
	var smooth_quat := current_quat.slerp(goal_rotation, 10.0 * delta)
	globe.transform.basis = Basis(smooth_quat)
	
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
			#rotating = event.pressed
			pass
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			pass
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			goal_zoom -= 0.005 * goal_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			goal_zoom += 0.005 * goal_zoom
	
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var v0 = (cursor._last_position - globe.global_position).normalized()
			var v1 = (cursor.global_position - globe.global_position).normalized()
			var axis = v0.cross(v1)
			var axis_len = axis.length()
			if axis_len > 1e-6:
				axis /= axis_len
				var angle := acos(clampf(v0.dot(v1), -1.0, 1.0))
				var delta_quat := Quaternion(axis, angle)
				goal_rotation = delta_quat * goal_rotation
		
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			var delta: Vector2 = event.relative
			var pan_speed := 0.01
			camera.translate(-camera.transform.basis.x * delta.x * pan_speed)
			camera.translate(camera.transform.basis.y * delta.y * pan_speed)



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
