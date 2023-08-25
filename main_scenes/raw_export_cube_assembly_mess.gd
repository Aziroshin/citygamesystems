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

#	var multi_tri := AMultiTri.new()
#	for i_face in range(len(vertices) / 3):
#		var offset = i_face * 3
#		var tri := ATri.new(
#			# Inverted
#			vertices[offset+2],
#			vertices[offset+1],
#			vertices[offset],
##			vertices[offset],
##			vertices[offset+1],
##			vertices[offset+2],
#		)
#		multi_tri.add_tri(tri)
#	multi_tri.apply_all()
	
	# Y-up
	for i_vert in range(len(vertices)):
		var vert := vertices[i_vert]
		var y := vert.y
		vert.y = vert.z
		vert.z = y
		
		vertices[i_vert] = vert
	
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	
	
	
func add_normals_to_surface_arrays(surface_arrays: Array, normals: PackedVector3Array):
	surface_arrays[ArrayMesh.ARRAY_NORMAL] = normals
	
	# For testing, to see whether the normals are flipped.
	var rearranged_normals = PackedVector3Array()
	for i_tri in range(len(normals) / 3):
		rearranged_normals.append(normals[3*i_tri])
		rearranged_normals.append(normals[3*i_tri+1])
		rearranged_normals.append(normals[3*i_tri+2])
		
	surface_arrays[ArrayMesh.ARRAY_NORMAL] = rearranged_normals
	
func add_uvs_to_surface_arrays(surface_arrays: Array, uvs: PackedVector2Array):
	
	var rearranged_uvs = PackedVector2Array()
	for i_tri in range(len(uvs) / 3):
		var uv1 = uvs[3*i_tri]
		var uv2 = uvs[3*i_tri+1]
		var uv3 = uvs[3*i_tri+2]
		
		rearranged_uvs.append(Vector2(uv1.x, 1.0 - uv1.y))
		rearranged_uvs.append(Vector2(uv2.x, 1.0 - uv2.y))
		rearranged_uvs.append(Vector2(uv3.x, 1.0 - uv3.y))
		
	surface_arrays[ArrayMesh.ARRAY_TEX_UV] = rearranged_uvs

	
func swap_array_values(
	array: Array,
	old_indices: PackedInt64Array,
	new_indices: PackedInt64Array
):
	assert(len(old_indices) == len(new_indices))
	
	var i_indices := 0
	for old_index in old_indices:
#		print("Swapping:")
#		print("old: ", array[old_index])
#		print("new: ", array[new_indices[i_indices]])
		var old_item = array[old_index]
		array[old_index] = array[new_indices[i_indices]]
		array[new_indices[i_indices]] = old_item
		i_indices += 1
	
func invert_surface_arrays(surface_arrays: Array):
	var array_vertex: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
	var array_uvs: PackedVector2Array = surface_arrays[ArrayMesh.ARRAY_TEX_UV]
	var array_normal: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_NORMAL]
	var length := len(array_vertex)
	
	for i_vert in range(length):
		var i_vert_inverted := length - i_vert - 1
		array_vertex[i_vert] = array_vertex[i_vert_inverted]
		array_uvs[i_vert] = array_uvs[i_vert_inverted]
		array_normal[i_vert] = array_normal[i_vert_inverted]
	
func invert_surface_arrays_faces(surface_arrays: Array):
	var array_vertex: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
	var array_uvs: PackedVector2Array = surface_arrays[ArrayMesh.ARRAY_TEX_UV]
	var array_normal: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_NORMAL]
	var length := len(array_vertex)
	
	for i_face in int(length / 3):
		var i_first_vert := i_face * 3
		var array_vertex_tmp := PackedVector3Array()
		array_vertex_tmp.append(array_vertex[i_first_vert])
		array_vertex_tmp.append(array_vertex[i_first_vert+1])
		array_vertex_tmp.append(array_vertex[i_first_vert+2])
		array_vertex[i_first_vert] = array_vertex_tmp[2]
		array_vertex[i_first_vert+2] = array_vertex_tmp[0]
		
		var array_uv_tmp := PackedVector2Array()
		array_uv_tmp.append(array_uvs[i_first_vert])
		array_uv_tmp.append(array_uvs[i_first_vert+1])
		array_uv_tmp.append(array_uvs[i_first_vert+2])
		array_uvs[i_first_vert] = array_uv_tmp[2]
		array_uvs[i_first_vert+2] = array_uv_tmp[0]
		
		# Doesn't work - abandoning for now. Spaghetti it is.
#		swap_array_values(
#			array_vertex,
#			[i_first_vert, i_first_vert+1, i_first_vert+2],
#			[i_first_vert+2, i_first_vert+1, i_first_vert]
#		)
#		swap_array_values(
#			array_uvs,
#			[i_first_vert, i_first_vert+1, i_first_vert+2],
#			[i_first_vert+2, i_first_vert+1, i_first_vert]
#		)
#		swap_array_values(
#			array_normal,
#			[i_first_vert, i_first_vert+1, i_first_vert+2],
#			[i_first_vert+2, i_first_vert+1, i_first_vert]
#		)

func flip_x(surface_arrays: Array):
	for i_vert in range(len(surface_arrays[ArrayMesh.ARRAY_VERTEX])):
		surface_arrays[ArrayMesh.ARRAY_VERTEX][i_vert].x =\
			-surface_arrays[ArrayMesh.ARRAY_VERTEX][i_vert].x

func swap_last_two(surface_arrays: Array):
	var array_vertex: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
	var array_uvs: PackedVector2Array = surface_arrays[ArrayMesh.ARRAY_TEX_UV]
	var array_normal: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_NORMAL]
	var length := len(array_vertex)
	
	for i_face in int(length / 3):
		var i_first_vert := i_face * 3
		var array_vertex_tmp := PackedVector3Array()
		array_vertex_tmp.append(array_vertex[i_first_vert])
		array_vertex_tmp.append(array_vertex[i_first_vert+1])
		array_vertex_tmp.append(array_vertex[i_first_vert+2])
		array_vertex[i_first_vert+1] = array_vertex_tmp[2]
		array_vertex[i_first_vert+2] = array_vertex_tmp[1]
		
		var array_uv_tmp := PackedVector2Array()
		array_uv_tmp.append(array_uvs[i_first_vert])
		array_uv_tmp.append(array_uvs[i_first_vert+1])
		array_uv_tmp.append(array_uvs[i_first_vert+2])
		array_uvs[i_first_vert+1] = array_uv_tmp[2]
		array_uvs[i_first_vert+2] = array_uv_tmp[1]

func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	Cavedig.needle(self, self.transform.translated(Vector3(3, 0, 0)), Vector3(1, 0, 0))
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 0, 1))
	
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	add_vertices_to_surface_arrays(surface_arrays, object_data.vertices)
	#add_indices_to_surface_arrays(surface_arrays, object_data.indices)
	add_normals_to_surface_arrays(surface_arrays, object_data.normals)
	add_uvs_to_surface_arrays(surface_arrays, object_data.uvs)
	
	# Swapping the last two vertices is inspired by this:
	# https://github.com/Ezcha/gd-obj/blob/1e1de657d0812bba93d70408a667c4718b5f34ab/obj-parse/ObjParse.gd#L251C41-L251C41
	swap_last_two(surface_arrays)
	# But without inverting the entire ARRAY_VERTEX (and ARRAY_NORMAL,
	# ARRAY_TEX_UV...) the surface is on the inside of the cube, so we invert:
	invert_surface_arrays_faces(surface_arrays)
	# And voilà! It finally works!! @.@
	
	var array_mesh_node := CityGeoFuncs.get_array_mesh_node(surface_arrays)
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_arrays[ArrayMesh.ARRAY_VERTEX]
		))
		
#	for i_face in range(len(surface_arrays[ArrayMesh.ARRAY_VERTEX]) / 3):
#		print(i_face)
#		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face])
#		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face+1])
#		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face+2])
#		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face])
#		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face+1])
#		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face+2])
	
	
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/parts/textures/coord_texture.png")
	var material2 := StandardMaterial3D.new()
	material2.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	var material_static := load("res://main_scenes/raw_export_cube_assembly_mess.tres")
	#array_mesh_node.set_surface_override_material(0, material_static)
	array_mesh_node.material_override = material
	
	array_mesh_node.set_scale(Vector3(-1, 1, 1))
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
