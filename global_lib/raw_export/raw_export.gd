extends RefCounted
class_name RawExport

const DEFAULT_MATERIAL_TYPE := "DEFAULT"
const BASIC_MATERIAL_TYPE := "BASIC"
const IMAGE_FILES_MATERIAL_TYPE := "IMAGE_FILES"


static func convert_array_to_color(p_array: Array) -> Color:
	if len(p_array) == 3:
		return Color(p_array[0], p_array[1], p_array[2])
	return Color(p_array[0], p_array[1], p_array[2], p_array[3])


static func convert_array_to_packed_vector3_array(p_array: Array) -> PackedVector3Array:
	var packed_vector3_array = PackedVector3Array()
	for element in p_array:
		if not element is Vector3 and not len(element) == 3:
			push_error("Not a Vector3 array.")
		packed_vector3_array.append(Vector3(element[0], element[1], element[2]))
	return packed_vector3_array
	
	
static func convert_array_to_packed_vector2_array(p_array: Array) -> PackedVector2Array:
	var packed_vector3_array = PackedVector2Array()
	for element in p_array:
		if not element is Vector2 and not len(element) == 2:
			push_error("Not a Vector2 array.")
		packed_vector3_array.append(Vector2(element[0], element[1]))
	return packed_vector3_array


class MaterialData extends JsonSerializable:
	var index: int
	var type: String
	var name: String
	
	func to_json() -> String:
		return JSON.stringify(to_dict())
	
	func to_dict() -> Dictionary:
		return {
			"type": type,
			"index": index,
			"name": name,
		}


class DefaultMaterialData extends MaterialData:
	func _init(p_index: int):
		type = DEFAULT_MATERIAL_TYPE
		index = p_index
		name = "Default"


static func DefaultMaterialData_from_dict(p_dict: Dictionary) -> DefaultMaterialData:
	return DefaultMaterialData.new(
		p_dict.index
	)


class BasicMaterialData extends MaterialData:
	var color: Color
	
	func _init(
		p_index: int,
		p_name: String,
		p_color: Color
	):
		type = BASIC_MATERIAL_TYPE
		index = p_index
		name = p_name
		color = p_color
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"color": color
		})
		return dict
		
		
static func BasicMaterialData_from_dict(p_dict:Dictionary) -> BasicMaterialData:
	return BasicMaterialData.new(
		p_dict.index,
		p_dict.name,
		RawExport.convert_array_to_color(p_dict.color)
	)


class ImageTextureMaterialData extends MaterialData:
	var filenames: PackedStringArray
	
	#static func from_json(json: String) -> ImageTextureMaterialData:
	#	return ImageTextureMaterialData.new(1, "", PackedStringArray())
	
	func _init(
		p_index: int,
		p_name: String,
		p_filenames: PackedStringArray
	):
		type = IMAGE_FILES_MATERIAL_TYPE
		index = p_index
		name = p_name
		filenames = p_filenames
		
	func add_filename(p_filename: String) -> void:
		filenames.append(p_filename)
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"filenames": filenames
		})
		return dict
		
		
static func ImageTextureMaterialData_from_dict(p_dict: Dictionary) -> ImageTextureMaterialData:
	return ImageTextureMaterialData.new(
		p_dict.index,
		p_dict.name,
		p_dict.filenames
	)
		
		
class RawObjectData extends JsonSerializable:
	var vertices: PackedVector3Array
	var normals: PackedVector3Array
	var uvs: PackedVector2Array
	var indices: PackedInt32Array
	var material_indices: PackedInt64Array
	var material_data: Array[MaterialData]
	
	func _init(
		p_vertices := PackedVector3Array(),
		p_normals := PackedVector3Array(),
		p_uvs := PackedVector2Array(),
		p_indices := PackedInt32Array(),
		p_material_indices := PackedInt64Array(),
		p_material_data: Array[MaterialData] = Array()
	):
		vertices = RawExport.convert_array_to_packed_vector3_array(p_vertices)
		normals = RawExport.convert_array_to_packed_vector3_array(p_normals)
		uvs = RawExport.convert_array_to_packed_vector2_array(p_uvs)
		indices = p_indices
		material_indices = p_material_indices
		material_data = p_material_data
		
	func to_json() -> String:
		return JSON.stringify(to_dict())
		
	func to_dict() -> Dictionary:
		var serialized_material_data: Array[MaterialData] = []
		for material in material_data:
			serialized_material_data.append(material.to_dict())
		return {
			"vertices": vertices,
			"normals": normals,
			"uvs": uvs,
			"indices": indices,
			"material_indices": material_indices,
			"material_data": serialized_material_data
		}


static func RawObjectData_from_json(p_json_string: String) -> RawObjectData:
	var obj: Dictionary = JSON.parse_string(p_json_string)
	
	var material_data: Array[MaterialData] = []
	for material in obj.materials:
		if material.type == DEFAULT_MATERIAL_TYPE:
			material_data.append(DefaultMaterialData_from_dict(material))
		elif material.type == BASIC_MATERIAL_TYPE:
			material_data.append(BasicMaterialData_from_dict(material))
		elif material.type == IMAGE_FILES_MATERIAL_TYPE:
			material_data.append(ImageTextureMaterialData_from_dict(material))
	
	return RawObjectData.new(
		RawExport.convert_array_to_packed_vector3_array(obj.vertices),
		RawExport.convert_array_to_packed_vector3_array(obj.normals),
		RawExport.convert_array_to_packed_vector2_array(obj.uvs),
		obj.indices,
		obj.material_indices,
		material_data
	)


class MaterialResolver:
	# @virtual
	func get_materials() -> Array[Material]:
		return []
	
	
class BasicMaterialResolver extends MaterialResolver:
	var material_data_array: Array[RawExport.MaterialData]
	
	func _init(p_material_data_array: Array[RawExport.MaterialData]):
		material_data_array = p_material_data_array
	
	func get_materials() -> Array[Material]:
		var materials: Array[Material] = []
		
		for basetype_material_data in material_data_array:
			if basetype_material_data.type == BASIC_MATERIAL_TYPE:
				# Uncomment if you want to access `material_data`.
				#var material_data := basetype_material_data as BasicMaterialData
				var material := StandardMaterial3D.new()
				material.albedo_color = Color(0, 1, 0.2)  # Green
				materials.append(material)
				
			elif basetype_material_data.type == IMAGE_FILES_MATERIAL_TYPE:
				var material_data := basetype_material_data as ImageTextureMaterialData
				# TODO: Evaluate whether we need to deal with multiple filenames
				#  and do it if we do need to do so.
				var albedo_base_path := "res://assets/parts/textures/%s" % material_data.filenames[0]
				# If some other part of the file name contains "albedo_base",
				# we're screwed. :p
				var normal_path := albedo_base_path.replace("albedo_base", "normal")
				var albedo_texture := load(albedo_base_path)
				var normal_texture := load(normal_path)
				var material := StandardMaterial3D.new()
				if albedo_texture:
					material.albedo_texture = albedo_texture
				if normal_texture:
					material.normal_texture = normal_texture
					material.normal_enabled = true
				#material.metallic = 0.0
				# material.roughness = 1.0
				#material.metallic_specular = 0.1
				materials.append(material)
			else:
				# Uncomment if you want to access `material_data`.
				#var material_data := basetype_material_data as DefaultMaterialData
				var material := StandardMaterial3D.new()
				material.albedo_color = Color(0.2, 0, 1)  # Blue
				materials.append(material)
				
		return materials
