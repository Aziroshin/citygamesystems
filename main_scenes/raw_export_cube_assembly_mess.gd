extends Node3D

const test_cube_path: StringName = "res://assets/parts/raw_export_test_cube.json"

### "Imports": MeshLib
const ATri := MeshLib.ATri
const AMultiTri := MeshLib.AMultiTri
const MFlipVerticesX := MeshLib.MFlipVerticesX
const MInvertSurfaceArrays := MeshLib.MInvertSurfaceArrays
const MYUp := MeshLib.MYUp
const MYFlipUVs := MeshLib.MYFlipUVs
### "imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay
### "Imports": RawExport
const DEFAULT_MATERIAL_TYPE := RawExport.DEFAULT_MATERIAL_TYPE
const DefaultMaterialData := RawExport.DefaultMaterialData
const BASIC_MATERIAL_TYPE := RawExport.BASIC_MATERIAL_TYPE
const BasicMaterialData := RawExport.BasicMaterialData
const IMAGE_FILES_MATERIAL_TYPE := RawExport.IMAGE_FILES_MATERIAL_TYPE
const ImageTextureMaterialData := RawExport.ImageTextureMaterialData


func load_and_get_raw_export(path: String):
	pass


func load_and_get_test_cube() -> Resource:
	return load_and_get_raw_export(test_cube_path)


func add_indices_to_surface_arrays(surface_arrays: Array, indices: PackedInt32Array):
	surface_arrays[ArrayMesh.ARRAY_INDEX] = indices


static func initialize_surface_arrays_via_meshlib(
	surface_arrays: Array,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array
):
	var multi_tri := AMultiTri.new()
	for i_face in range(len(vertices) / 3):
		var offset = i_face * 3
		var tri := ATri.new(
			vertices[offset],
			vertices[offset+1],
			vertices[offset+2],
			
			normals[offset],
			normals[offset+1],
			normals[offset+2],
			
			uvs[offset],
			uvs[offset+1],
			uvs[offset+2]
		)
		multi_tri.add_tri(tri)
	multi_tri.add_modifier(MYFlipUVs.new())
	multi_tri.add_modifier(MYUp.new())
	multi_tri.add_modifier(MFlipVerticesX.new())
	multi_tri.add_modifier(MInvertSurfaceArrays.new())
	multi_tri.apply_all()
	
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = multi_tri.get_array_vertex()
	surface_arrays[ArrayMesh.ARRAY_NORMAL] = multi_tri.get_array_normal()
	surface_arrays[ArrayMesh.ARRAY_TEX_UV] = multi_tri.get_array_tex_uv()
	
	
func get_grouped_surfaces_by_material_index(
	material_indices: PackedInt64Array,
	surface_arrays: Array,
	primitive_n := 3
) -> Array[Array]:
	var array_vertex: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
	var array_tex_uv: PackedVector2Array = surface_arrays[ArrayMesh.ARRAY_TEX_UV]
	var array_normal: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_NORMAL]
	var face_count := len(array_vertex) / 3
	var grouped: Array[Array] = []
	
	### Initialize our array of surface arrays.
	var highest_material_index := 0
	for material_index in material_indices:
		highest_material_index = max(highest_material_index, material_index)
	grouped.resize(highest_material_index + 1)
	for i_material in range(highest_material_index + 1):
		var group_surface_arrays := []
		group_surface_arrays.resize(ArrayMesh.ARRAY_MAX)
		group_surface_arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array()
		group_surface_arrays[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array()
		group_surface_arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array()
		grouped[i_material] = group_surface_arrays
	
	var i_face := 0
	for material_index in material_indices:
		var group_surface_arrays := grouped[material_index]
		var group_array_vertex: PackedVector3Array\
			= group_surface_arrays[ArrayMesh.ARRAY_VERTEX]
		var group_array_tex_uv: PackedVector2Array\
			= group_surface_arrays[ArrayMesh.ARRAY_TEX_UV]
		var group_array_normal: PackedVector3Array\
			= group_surface_arrays[ArrayMesh.ARRAY_NORMAL]
		
		group_array_vertex.append(array_vertex[primitive_n * i_face])
		group_array_vertex.append(array_vertex[primitive_n * i_face + 1])
		group_array_vertex.append(array_vertex[primitive_n * i_face + 2])
		
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face])
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face + 1])
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face + 2])
		
		group_array_normal.append(array_normal[primitive_n * i_face])
		group_array_normal.append(array_normal[primitive_n * i_face + 1])
		group_array_normal.append(array_normal[primitive_n * i_face + 2])
		
		group_surface_arrays[ArrayMesh.ARRAY_VERTEX] = group_array_vertex
		group_surface_arrays[ArrayMesh.ARRAY_TEX_UV] = group_array_tex_uv
		group_surface_arrays[ArrayMesh.ARRAY_NORMAL] = group_array_normal
		grouped[material_index] = group_surface_arrays
		
		i_face += 1
	
	return grouped
	
func get_materials(
	material_data_array: Array[RawExport.MaterialData]
) -> Array[StandardMaterial3D]:
	var materials: Array[StandardMaterial3D] = []
	
	for basetype_material_data in material_data_array:
		if basetype_material_data.type == DEFAULT_MATERIAL_TYPE:
			var material_data: DefaultMaterialData = basetype_material_data
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.2, 0, 1)  # Blue
			materials.append(material)
			
		if basetype_material_data.type == BASIC_MATERIAL_TYPE:
			var material_data: BasicMaterialData = basetype_material_data
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0, 1, 0.2)  # Green
			materials.append(material)
			
		if basetype_material_data.type == IMAGE_FILES_MATERIAL_TYPE:
			var material_data: ImageTextureMaterialData = basetype_material_data
			var material := StandardMaterial3D.new()
			material.albedo_texture = load(
				"res://assets/parts/textures/coord_texture.png"
			)
			materials.append(material)
			
	return materials
	
	
static func get_inverted_material_indices(material_indices: PackedInt64Array):
	var inverted_material_indices := PackedInt64Array()
	var length := len(material_indices)
	for i_index in range(length):
		var i_index_inverted := length - i_index - 1
		inverted_material_indices.append(material_indices[i_index_inverted])
	return inverted_material_indices
	
	
func _mess(show_debug_overlay) -> Node3D:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data := RawExport.RawObjectData_from_json(file)
	
	const DEFAULT_MATERIAL_TYPE = "DEFAULT"
	const BASIC_MATERIAL_TYPE = "BASIC"
	const IMAGE_FILES_MATERIAL_TYPE = "IMAGE_FILES"
	
	# Red needle: +X (Godot)
	Cavedig.needle(self, self.transform.translated(Vector3(3, 0, 0)), Vector3(1, 0, 0), 10.0, 0.02)
	# Blue needle with green disc: +Z (Godot) and +Y (Blender)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 0, 1), 10.0, 0.02)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 1, 0), 0.05, 0.1)
	
	var surface_arrays := []
	var material_indices := object_data.material_indices
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	initialize_surface_arrays_via_meshlib(
		surface_arrays,
		object_data.vertices,
		object_data.normals,
		object_data.uvs
	)
	material_indices = get_inverted_material_indices(material_indices)
	
	var grouped_surface_arrays := get_grouped_surfaces_by_material_index(
		material_indices,
		surface_arrays
	)
	
	var array_mesh_node := CityGeoFuncs.get_multi_surface_array_mesh_node(
		grouped_surface_arrays
	)
	
	# Need to redo this for the new surface array groups.
	if show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_arrays[ArrayMesh.ARRAY_VERTEX]
		))
		
	var materials := get_materials(object_data.materials)
	for i_material in range(len(materials)):
		array_mesh_node.mesh.surface_set_material(i_material, materials[i_material])
	
	return array_mesh_node
	
	
func _ready() -> void:
	add_child(_mess(true))
