extends Node3D
class_name Curve3DDebugBakedBasesVisualizer

@export var curve_changed := true
@export var curve := Curve3D.new():
	set(p_value):
		curve_changed = true
		curve = p_value
## The (non-baked) point indexes that are supposed to be visualized. If [0] is
## -1, all points are visualized (default). If the array is empty, no points
## will be visualized.
## Any indexes which don't correspond to points on the curve will be skipped
## silently. Treat this as a "wishlist" of sorts of curve points you'd like to
## have visualized if they're found on the curve.
@export var visualized_indexes := [-1]

## Returns the number of elements in `.visualized_indexes`, or the value of
## `.curve.point_count` if [0] of `visualized_indexes` is `-1`.
func get_visualized_indexes_count() -> int:
	if len(visualized_indexes) > 0 and visualized_indexes[0] == -1:
		return curve.point_count
	else:
		return len(visualized_indexes)


func _update_visualization() -> void:
	pass


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_visualization()
