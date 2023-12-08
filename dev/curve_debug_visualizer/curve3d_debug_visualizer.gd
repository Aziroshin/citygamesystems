@tool
extends Node3D
class_name Curve3DDebugVisualizer

var path := Path3D.new()
@export var initial_curve := Curve3D.new()
@export var get_curve_by_signal := false

var profile_mesh := CSGPolygon3D.new()
var curve_changed := false


func _config_profile_mesh(mesh: CSGPolygon3D):
	mesh.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 0.2),
		Vector2(0.2, 0.2),
		Vector2(0.2, 0)
	])
	mesh.path_joined = true
	mesh.path_interval = 0.05
	

func _ready() -> void:
	path.curve = initial_curve
	path.curve.add_point(Vector3(0.0, 0.0, 0.0))
	path.curve.add_point(Vector3(0.01, 0.5, 0.5))
	path.curve.add_point(Vector3(2.6, 2.3, 2.0))
	path.curve.add_point(Vector3(1.9, 3.7, 3.0))
	path.curve.add_point(Vector3(3.5, 4.6, 2.2))
	path.curve.add_point(Vector3(1.2, 4.6, 2.2))
	
	#add_child(path)
	add_child(profile_mesh)
	
	profile_mesh.mode = profile_mesh.MODE_PATH
	profile_mesh.path_node = profile_mesh.get_path_to(path)
	profile_mesh.path_continuous_u = false
	profile_mesh.path_joined = false
	profile_mesh.path_interval = 0.1
	_config_profile_mesh(profile_mesh)
	
	# TODO [cavedev]: Trying out `ArrayMesh` based curve rendering.
	var array_mesh_curve := Curve3DMesh.new()
	# Some pseudo values to see something for now.
	array_mesh_curve.curve.add_point(Vector3(0.0, 0.0, 0.0))
	array_mesh_curve.curve.add_point(Vector3(0.01, 0.5, 0.5))
	array_mesh_curve.curve.add_point(Vector3(2.6, 2.3, 2.0))
	array_mesh_curve.curve.add_point(Vector3(1.9, 3.7, 3.0))
	array_mesh_curve.curve.add_point(Vector3(3.5, 4.6, 2.2))
	array_mesh_curve.curve.add_point(Vector3(1.2, 4.6, 2.2))
	add_child(array_mesh_curve)
	print(array_mesh_curve.curve.point_count)
	

func _process(_p_delta: float) -> void:
	if curve_changed:
		pass


func _on_curve_changed(p_curve: Curve3D) -> void:
	if get_curve_by_signal:
		curve_changed = true
		path.curve = p_curve
		
