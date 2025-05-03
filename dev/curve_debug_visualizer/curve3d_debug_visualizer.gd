@tool
extends Node3D
class_name Curve3DDebugVisualizer

### Dependencies:
# - Curve3DDebugFuncs

var curve_mesh := Curve3DDebugMesh.new()
var handle_visualizer := Curve3DDebugHandleVisualizer.new()
var rendered_handle_count := 0
var curve_changed := false
@export var curve := Curve3D.new():
	get:
		return curve
	set(p_value):
		curve = p_value
		curve_changed = true
@export var curve_material := curve_mesh.material:
	get:
		return curve_mesh.material
	set(p_value):
		curve_mesh.material = p_value
@export var in_handle_material := handle_visualizer.in_handle_material:
	get:
		return handle_visualizer.in_handle_material
	set(p_value):
		handle_visualizer.in_handle_material = p_value
@export var out_handle_material := handle_visualizer.out_handle_material:
	get:
		return handle_visualizer.out_handle_material
	set(p_value):
		handle_visualizer.out_handle_material = p_value
@export var tangent_material := handle_visualizer.tangent_material:
	get:
		return handle_visualizer.tangent_material
	set(p_value):
		handle_visualizer.tangent_material = p_value
@export var get_curve_by_signal := false
@export var visualized_indexes: PackedInt64Array:
	get:
		return handle_visualizer.visualized_indexes
	set(p_value):
		handle_visualizer.visualized_indexes = p_value
@export var visualize_transforms := false
@export var transform_visualizer: CavedigTransform3DVisualizer
var curve_transform_visualizer := Curve3DDebugBakedTransformVisualizer.new()


func _ready() -> void:
	if transform_visualizer == null:
		transform_visualizer = CavedigTransform3DVisualizer.new()
	add_child(curve_transform_visualizer)
	curve_transform_visualizer.visualizer = transform_visualizer
	add_child(curve_mesh)
	add_child(handle_visualizer)
	_update_curve_mesh()


func _update_curve_mesh():
	curve_mesh.update_from_curve(curve)


func _update_visualization() -> void:
	curve_changed = false
	_update_curve_mesh()


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_visualization()


func _on_curve_changed(p_curve: Curve3D) -> void:
	if get_curve_by_signal:
		curve = p_curve
		handle_visualizer.set_curve(p_curve)
		if visualize_transforms:
			curve_transform_visualizer.set_curve(p_curve)


func _on_street_tool_curve_changed(p_curve_copy: Curve3D) -> void:
	pass # Replace with function body.
