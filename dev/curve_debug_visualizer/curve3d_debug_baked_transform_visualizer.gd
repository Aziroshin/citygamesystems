extends Node3D
class_name Curve3DDebugBakedTransformVisualizer

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
@export var visualizer: CavedigTransform3DVisualizer:
	set(p_value):
		if not p_value == null and p_value.get_parent() == null:
			if not visualizer == null and visualizer.get_parent() == self:
				remove_child(visualizer)
			add_child(p_value)
		visualizer = p_value


# Set `p_curve` as the new curve and update the visualization based on it.
# If [0] of `p_visualized_indexes` is `-2`, the parameter will be
# ignored (default). `-1` means that all points will be visualized and an empty
# array means none will be.
func set_curve(
	p_curve: Curve3D,
	p_visualized_indexes := PackedInt64Array([-2])
) -> void:
	curve = p_curve
	if len(p_visualized_indexes) > 0 and not p_visualized_indexes[0] == -2:
		visualized_indexes = p_visualized_indexes


## Returns the number of elements in `.visualized_indexes`, or the value of
## `.curve.point_count` if [0] of `visualized_indexes` is `-1`.
func get_visualized_indexes_count() -> int:
	if len(visualized_indexes) > 0 and visualized_indexes[0] == -1:
		return curve.point_count
	else:
		return len(visualized_indexes)


func _update_visualization() -> void:
	curve_changed = false
	visualizer.reset()
	
	#TODO
	if curve.point_count > 1:
		for _transform in GeoFoo.get_baked_point_transforms(curve):
			visualizer.add(_transform)
	visualizer.bake()
	


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_visualization()
