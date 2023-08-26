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


static func get_y_upped(vertex: Vector3) -> Vector3:
	var y := vertex.y
	vertex.y = vertex.z
	vertex.z = y
	return vertex


static func y_up_vertices(vertices: PackedVector3Array) -> PackedVector3Array:
	for i_vert in range(len(vertices)):
		vertices[i_vert] = get_y_upped(vertices[i_vert])
	return vertices


static func add_vertices_to_surface_arrays(surface_arrays: Array, vertices: PackedVector3Array):

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
	y_up_vertices(vertices)
	
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	
	
func add_normals_to_surface_arrays(surface_arrays: Array, normals: PackedVector3Array):
	surface_arrays[ArrayMesh.ARRAY_NORMAL] = normals
	
	
func add_uvs_to_surface_arrays(surface_arrays: Array, uvs: PackedVector2Array):
	# We Y-flip the UVs, since in Blender Y-zero is at the bottom and in Godot
	# it's at the top. The exporter should probably have a flag for this.
	var y_flipped_uvs = PackedVector2Array()
	for i_tri in range(len(uvs) / 3):
		var uv1 = uvs[3*i_tri]
		var uv2 = uvs[3*i_tri+1]
		var uv3 = uvs[3*i_tri+2]
		
		y_flipped_uvs.append(Vector2(uv1.x, 1.0 - uv1.y))
		y_flipped_uvs.append(Vector2(uv2.x, 1.0 - uv2.y))
		y_flipped_uvs.append(Vector2(uv3.x, 1.0 - uv3.y))
		
	surface_arrays[ArrayMesh.ARRAY_TEX_UV] = y_flipped_uvs
	
	
static func swap_array_values(
	array,  # Needs to be able to take any of the surface_arrays "array" types.
	old_indices: PackedInt64Array,
	new_indices: PackedInt64Array
):
	assert(len(old_indices) == len(new_indices))
	
	var i_indices := 0
	for old_index in old_indices:
		var new_index := new_indices[i_indices]
		var old_item = array[old_index]
		var new_item = array[new_index]

		array[old_index] = new_item
		array[new_index] = old_item
		
		i_indices += 1
	return array
	
	
static func swap_values_of_arrays(
	arrays: Array,
	old_indices: PackedInt64Array,
	new_indices: PackedInt64Array
) -> Array:
	var i_array := 0
	for array in arrays:
		swap_array_values(array, old_indices, new_indices)
		
	return arrays
	
	
static func invert_surface_arrays_tris(surface_arrays: Array):
	for i_face in int(len(surface_arrays[ArrayMesh.ARRAY_VERTEX]) / 3):
		var i_first_vert := i_face * 3
		swap_values_of_arrays(
			[
				surface_arrays[ArrayMesh.ARRAY_VERTEX],
				surface_arrays[ArrayMesh.ARRAY_TEX_UV],
				surface_arrays[ArrayMesh.ARRAY_NORMAL]
			],
			[i_first_vert],
			[i_first_vert+2]
		)
		
		
static func swap_last_vertices_two_for_each_tri(surface_arrays: Array):
	for i_face in int(len(surface_arrays[ArrayMesh.ARRAY_VERTEX]) / 3):
		var i_first_vert := i_face * 3
		swap_values_of_arrays(
			[
				surface_arrays[ArrayMesh.ARRAY_VERTEX],
				surface_arrays[ArrayMesh.ARRAY_TEX_UV],
				surface_arrays[ArrayMesh.ARRAY_NORMAL]
			],
			[i_first_vert+1],
			[i_first_vert+2]
		)
		
func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	# Red needle: +X (Godot)
	Cavedig.needle(self, self.transform.translated(Vector3(3, 0, 0)), Vector3(1, 0, 0), 10.0, 0.02)
	# Blue needle with green disc: +Z (Godot) and +Y (Blender)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 0, 1), 10.0, 0.02)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 1, 0), 0.05, 0.1)
	
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	add_vertices_to_surface_arrays(surface_arrays, object_data.vertices)
	add_normals_to_surface_arrays(surface_arrays, object_data.normals)
	add_uvs_to_surface_arrays(surface_arrays, object_data.uvs)
	
	# Swapping the last two vertices is inspired by this:
	# https://github.com/Ezcha/gd-obj/blob/1e1de657d0812bba93d70408a667c4718b5f34ab/obj-parse/ObjParse.gd#L251C41-L251C41
	swap_last_vertices_two_for_each_tri(surface_arrays)
	# But without inverting each tri the surface is on the inside of the cube,
	# so we invert:
	invert_surface_arrays_tris(surface_arrays)
	
	var array_mesh_node := CityGeoFuncs.get_array_mesh_node(surface_arrays)
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_arrays[ArrayMesh.ARRAY_VERTEX]
		))
	
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/parts/textures/coord_texture.png")
	var material2 := StandardMaterial3D.new()
	material2.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	var material_static := load("res://main_scenes/raw_export_cube_assembly_mess.tres")
	array_mesh_node.material_override = material
	
	# array_mesh_node.set_scale(Vector3(-1, 1, 1))
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
