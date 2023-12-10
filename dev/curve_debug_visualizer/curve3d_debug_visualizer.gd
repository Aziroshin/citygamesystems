@tool
extends Node3D
class_name Curve3DDebugVisualizer

var curve_mesh := Curve3DMesh.new()
var curve_changed := false
@export var curve := Curve3D.new():
	get:
		return curve
	set(p_value):
		curve = p_value
		curve_changed = true
@export var get_curve_by_signal := false


func _ready() -> void:
	add_child(curve_mesh)
	_update_curve_mesh()


func _update_curve_mesh():
	curve_changed = false
	curve_mesh.update(curve)


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_curve_mesh()


func _on_curve_changed(p_curve: Curve3D) -> void:
	if get_curve_by_signal:
		curve = p_curve
		curve_changed = true
