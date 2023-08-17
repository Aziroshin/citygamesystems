extends Node3D

const test_cube_path: StringName = "res://assets/parts/raw_export_test_cube.json"

### "Imports": MeshLib
const ATri := MeshLib.ATri
const AMultiTri := MeshLib.AMultiTri
### "imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay


func load_and_get_raw_export(path: String):
	pass


func load_and_get_test_cube() -> Resource:
	return load_and_get_raw_export(test_cube_path)


func add_indices_to_surface_arrays(surface_arrays: Array, indices: PackedInt32Array):
	surface_arrays[ArrayMesh.ARRAY_INDEX] = indices


func add_vertices_to_surface_arrays(surface_arrays: Array, vertices: PackedVector3Array):
	var multi_tri := AMultiTri.new()
	for i_face in range(len(vertices) / 3):
		var offset = i_face * 3
		var tri := ATri.new(
			vertices[offset],
			vertices[offset+1],
			vertices[offset+2],
		)
		multi_tri.add_tri(tri)
	multi_tri.apply_all()

	var surface_array_vertex := multi_tri.get_array_vertex()
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = surface_array_vertex


func add_normals_to_surface_arrays(surface_arrays: Array, normals: PackedVector3Array):
	surface_arrays[ArrayMesh.ARRAY_NORMAL] = normals


func add_uvs_to_surface_arrays(surface_arrays: Array, uvs: PackedVector2Array):
	surface_arrays[ArrayMesh.ARRAY_TEX_UV] = uvs


func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	add_vertices_to_surface_arrays(surface_arrays, object_data.vertices)
	add_indices_to_surface_arrays(surface_arrays, object_data.indices)
	add_normals_to_surface_arrays(surface_arrays, object_data.normals)
	
	var array_mesh_node = CityGeoFuncs.get_array_mesh_node(surface_arrays)
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_arrays[ArrayMesh.ARRAY_VERTEX]
		))
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
