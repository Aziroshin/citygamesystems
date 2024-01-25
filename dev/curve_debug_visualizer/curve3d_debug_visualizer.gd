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
@export var curve_material: StandardMaterial3D:
	get:
		return curve_mesh.material
	set(p_value):
		curve_mesh.material = p_value
@export var in_handle_material: StandardMaterial3D:
	get:
		return handle_visualizer.in_handle_material
	set(p_value):
		handle_visualizer.in_handle_material = p_value
@export var out_handle_material: StandardMaterial3D:
	get:
		return handle_visualizer.out_handle_material
	set(p_value):
		handle_visualizer.out_handle_material = p_value
@export var tangent_material: StandardMaterial3D:
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


func _ready() -> void:
	# curve_mesh.profile2d = _get_tangent_profile2d()
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
