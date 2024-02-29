extends ToolLibMapAgent
# Since this is not part of `ToolLib`, we drop the `Lib` part here.
class_name ToolPlaneMapAgent

@export var map: PlaneMap


func _ready() -> void:
	map.mouse_motion.connect(_on_mouse_motion)
	map.mouse_position_change.connect(_on_mouse_position_change)
	map.mouse_button.connect(_on_mouse_button)


func get_map_node() -> Node3D:
	return map
