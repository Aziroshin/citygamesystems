extends Node3D

@onready var map: PlaneMap = $Map


func _ready() -> void:
	pass
	
func _process(delta) -> void:
	pass

func _on_map_mouse_button(
	camera: Camera3D,
	event: InputEvent,
	mouse_position: Vector3,
	normal: Vector3,
	shape: int
) -> void:
	Cavedig.needle(self.map, Transform3D(Basis(), mouse_position))
