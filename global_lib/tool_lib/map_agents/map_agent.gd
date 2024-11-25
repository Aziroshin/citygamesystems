extends Node
class_name ToolLibMapAgent

# Dependencies:
# - ToolLibToolMapPositioner

var positioner := ToolLibToolPositioner.new()


signal mouse_motion(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
)
signal mouse_position_change(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
)
signal mouse_button(
	p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_click_position: Vector3,
	p_click_normal: Vector3,
	p_shape: int
)


func _ready():
	for child in get_children():
		if child is ToolLibToolPositioner:
			positioner = child


# Override in sub-class.
func get_map_node() -> Node3D:
	push_warning(
		"ToolLibMapAgent `get_map_node` func not overridden. ",
		"Returning `Node3D.new()`. ",
		"Map agent node path: %s." % get_path()
	)
	return Node3D.new()


func _on_mouse_motion(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
) -> void:
	mouse_motion.emit(p_camera, p_event, p_position, p_normal, p_shape)


func _on_mouse_position_change(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
) -> void:
	mouse_position_change.emit(p_camera, p_event, p_position, p_normal, p_shape)


func _on_mouse_button(
	p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_click_position: Vector3,
	p_click_normal: Vector3,
	p_shape: int
) -> void:
	mouse_button.emit(p_camera, p_event, p_click_position, p_click_normal, p_shape)


func get_position(p_reference_position: Vector3) -> Vector3:
	return positioner.get_position(p_reference_position)
