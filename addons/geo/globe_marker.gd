@tool
@icon("VisibleOnScreenNotifier3D")
class_name GlobeMarker extends Node3D

@export var icon: Node2D = get_child(0)
@export var lonlat := Vector2.ZERO: set=set_lonlat

func set_lonlat(v: Vector2):
	lonlat = v
	look_at_from_position(GeoJSON.lonlat_to_vec3(lonlat), Vector3.ZERO, Vector3.UP)
