extends CanvasItem

signal globe_front_entered() ## Marker entered front of globe from camera perspective.
signal globe_front_exited() ## Marker is occluded by globe from camera perspective.

func _ready() -> void:
	globe_front_entered.connect(_entered)
	globe_front_exited.connect(_exited)

func _entered():
	modulate.a = 1.0

func _exited():
	modulate.a = 0.1
