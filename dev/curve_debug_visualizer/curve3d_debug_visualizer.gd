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
@export var curve_material := StandardMaterial3D.new():
	get:
		return curve_mesh.material
	set(p_value):
		curve_mesh.material = p_value
@export var tangent_material := StandardMaterial3D.new():
	get:
		return handle_visualizer.tangent_material
	set(p_value):
		handle_visualizer.tangent_material = p_value
@export var get_curve_by_signal := false


func _ready() -> void:
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
	 #Debug: Faking in points.
	#var offset_1 := 0.0
	#var offset_2 := 3.0
	#for i_point in p_curve.point_count:
		##print("_on_curve_changed: ", p_curve.get_point_position(i_point) - Vector3(1.0, 0.0, 1.0))
		#p_curve.set_point_in(i_point, p_curve.get_point_position(i_point) - Vector3(1.0+offset_1, sin(offset_1), 1.0-offset_1))
		#p_curve.set_point_out(i_point, p_curve.get_point_position(i_point) - Vector3(-1.0+offset_2, sin(offset_2), -1.0-offset_2))
		#offset_1 += 0.5
		#offset_2 = 0.5
	
	if get_curve_by_signal:
		curve = p_curve
		handle_visualizer.set_curve(p_curve)
