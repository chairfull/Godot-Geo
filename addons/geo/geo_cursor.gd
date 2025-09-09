extends Node3D

@onready var globe: Node3D = %globe

var _last_position := Vector3.ZERO

func _process(delta: float) -> void:
	#scale = Vector3.ONE * pow(goal_zoom, 4.0) * .01
	
	var lonlat := UGeo.vec3_to_lonlat(global_position * globe.global_basis)
	
	%debug_label.text = str(lonlat)
	var hovered: Node = null
	for node: GeoJSONMesh in get_tree().get_nodes_in_group(&"collide_test"):
		var feature := node.get_feature_at_lonlat(lonlat)
		if feature:
			%debug_label.text = str(feature.properties.get("name_en", feature.keys()))
			break

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera := get_viewport().get_camera_3d()
		var ray_origin := camera.global_transform.origin
		var ray_dir := camera.project_ray_normal(event.position)
		var hit_point := UGeo.ray_sphere_intersect(ray_origin, ray_dir, globe.global_position)
		if hit_point:
			_last_position = global_position
			global_position = hit_point
