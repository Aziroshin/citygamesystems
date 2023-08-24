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
			# Inverted
#			vertices[offset+2],
#			vertices[offset+1],
#			vertices[offset],
			vertices[offset],
			vertices[offset+1],
			vertices[offset+2],
		)
		multi_tri.add_tri(tri)
	multi_tri.apply_all()
	#multi_tri.flip_tris()
	#multi_tri.apply_all()

	#var surface_array_vertex := multi_tri.get_array_vertex()
	#surface_arrays[ArrayMesh.ARRAY_VERTEX] = surface_array_vertex
	
	# Y-up
	for i_vert in range(len(vertices)):
		var vert := vertices[i_vert]
		var y := vert.y
		vert.y = vert.z
		vert.z = y
		vertices[i_vert] = vert
	
	# For UV Y-Flip
#	for i_vert in range(3):
#		var i_mid_vert := i_vert + 1
#		var mid_vert := vertices[i_mid_vert]
#		vertices[i_mid_vert] = vertices[i_vert]
#		vertices[i_vert] = mid_vert
	
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	
	print(surface_arrays[ArrayMesh.ARRAY_VERTEX])
	
#	surface_arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array()
#	for i_quad in range(len(vertices) / 6):
#
#		var v0 = Vector3(vertices[6*i_quad])
#		var v1 = Vector3(vertices[6*i_quad+1])
#		var v2 = Vector3(vertices[6*i_quad+2])
#		var v3 = Vector3(vertices[6*i_quad+3])
#		var v4 = Vector3(vertices[6*i_quad+4])
#		var v5 = Vector3(vertices[6*i_quad+5])
#
#		# First tri.
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v2)
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v1)
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v0)
#
#		# Second tri.
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v5)
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v4)
#		surface_arrays[ArrayMesh.ARRAY_VERTEX].append(v3)
#
#	print("len: ", len(surface_arrays[ArrayMesh.ARRAY_VERTEX]))
#	var offset = 30
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset])
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset+1])
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset+2])
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset+3])
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset+4])
#	print(surface_arrays[ArrayMesh.ARRAY_VERTEX][offset+5])
	
	
	
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
		# Invert (to match inverted vertices).
		
		# Blue Test.
#		rearranged_uvs.append(Vector2(0.62, 0.25))
#		rearranged_uvs.append(Vector2(0.87, 0.5))
#		rearranged_uvs.append(Vector2(0.62, 0.5))
		
		# Bug: UV coordinates are behaving y-flipped.
#		rearranged_uvs.append(uvs[3*i_tri+2])
#		rearranged_uvs.append(uvs[3*i_tri+1])
#		rearranged_uvs.append(uvs[3*i_tri])
		
		var uv1 = uvs[3*i_tri]
		var uv2 = uvs[3*i_tri+1]
		var uv3 = uvs[3*i_tri+2]
		
		# Bug: Not mirrored anymore, but the mapping is broken in some places.
		# It's still rotated by 180° now, though. 
		# I guess the mapping on +Y results in y=1 or y=0 due to the
		# calculations done below, that's why that one's broken.
		# -X, +Y and -Y are a "pair", and everything else is flipped 180°
		# relative to them.
		rearranged_uvs.append(Vector2(uv1.x, 1.0 - uv1.y))
		rearranged_uvs.append(Vector2(uv2.x, 1.0 - uv2.y))
		rearranged_uvs.append(Vector2(uv3.x, 1.0 - uv3.y))

#		rearranged_uvs.append(Vector2(uv1.x, uv1.y))
#		rearranged_uvs.append(Vector2(uv2.x, uv2.y))
#		rearranged_uvs.append(Vector2(uv3.x, uv3.y))
		
	surface_arrays[ArrayMesh.ARRAY_TEX_UV] = rearranged_uvs
	
#	var i := 0
#	for uv in uvs:
#		surface_arrays[ArrayMesh.ARRAY_TEX_UV][i] = surface_arrays[ArrayMesh.ARRAY_TEX_UV][i] * -1
#		i += 1

func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	add_vertices_to_surface_arrays(surface_arrays, object_data.vertices)
	#add_indices_to_surface_arrays(surface_arrays, object_data.indices)
	add_normals_to_surface_arrays(surface_arrays, object_data.normals)
	add_uvs_to_surface_arrays(surface_arrays, object_data.uvs)
	
	var array_mesh_node := CityGeoFuncs.get_array_mesh_node(surface_arrays)
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_arrays[ArrayMesh.ARRAY_VERTEX]
		))
		
		
	for i_face in range(len(surface_arrays[ArrayMesh.ARRAY_VERTEX]) / 3):
		print(i_face)
		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face])
		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face+1])
		print(surface_arrays[ArrayMesh.ARRAY_VERTEX][3*i_face+2])
		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face])
		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face+1])
		print(surface_arrays[ArrayMesh.ARRAY_TEX_UV][3*i_face+2])
	
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/parts/textures/coord_texture.png")
	var material2 := StandardMaterial3D.new()
	material2.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	var material_static := load("res://main_scenes/raw_export_cube_assembly_mess.tres")
	#array_mesh_node.set_surface_override_material(0, material_static)
	array_mesh_node.material_override = material
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
