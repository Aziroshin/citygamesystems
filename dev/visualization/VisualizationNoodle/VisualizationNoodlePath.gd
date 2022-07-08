@tool
extends Path3D
class_name VisualizationNoodlePath

# Since we're also using builder methods for setting and getting start
# and end position, but, at the same time, want tool-compatible
# configurability and the ability to set default values, we're "setgetting"
# the builder methods here.
@export var start: Vector3 = Vector3(0, 0, 1):
	get:
		return get_start()
	set(value):
		set_start(value)
@export var end: Vector3 = Vector3(0, 0, -1):
	get:
		return get_end()
	set(value):
		set_end(value)

func _init():
	curve.add_point(start)
	curve.add_point(end)

func get_end_idx() -> int:
	return curve.get_point_count() - 1

func get_end() -> Vector3:
	return curve.get_point_position(get_end_idx())

func get_start() -> Vector3:
	return curve.get_point_position(0)

func set_start(position: Vector3) -> VisualizationNoodlePath:
	curve.set_point_position(0, position)
	return self

func set_end(position: Vector3) -> VisualizationNoodlePath:
	curve.set_point_position(get_end_idx(), position)
	return self

func _enter_tree():
	curve.clear_points()
	curve.add_point(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0))
	curve.add_point(Vector3(0, 0, -1), Vector3(0, 0, 0), Vector3(0, 0, 0))
