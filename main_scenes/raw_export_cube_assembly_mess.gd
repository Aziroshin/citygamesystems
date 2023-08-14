extends Node3D

const test_cube_path: StringName = "res://assets/parts/raw_export_test_cube.json"

### "Imports": MeshLib
const AQuad := MeshLib.AQuad
const AMultiQuad := MeshLib.AMultiQuad
### "imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay


func load_and_get_raw_export(path: String):
	pass


func load_and_get_test_cube() -> Resource:
	return load_and_get_raw_export(test_cube_path)


func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	var multi_quad := AMultiQuad.new()
	for i_face in range(len(object_data.vertices) / 4):
		var offset = i_face * 4
		var quad := AQuad.new(
			object_data.vertices[offset],
			object_data.vertices[offset+1],
			object_data.vertices[offset+2],
			object_data.vertices[offset+3]
		)
		multi_quad.add_quad(quad)
	multi_quad.apply_all()

	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	var surface_array_vertex := multi_quad.get_array_vertex()
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = surface_array_vertex
	
	var array_mesh_node = CityGeoFuncs.get_array_mesh_node(surface_arrays)
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			multi_quad.get_array_vertex()
		))
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
