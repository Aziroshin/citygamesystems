extends RefCounted
class_name RawExport

const DEFAULT_MATERIAL_TYPE := "DEFAULT"
const BASIC_MATERIAL_TYPE := "BASIC"
const IMAGE_FILES_MATERIAL_TYPE := "IMAGE_FILES"


static func convert_array_to_color(array: Array) -> Color:
	if len(array) == 3:
		return Color(array[0], array[1], array[2])
	return Color(array[0], array[1], array[2], array[3])


static func convert_array_to_packed_vector3_array(array: Array) -> PackedVector3Array:
	var packed_vector3_array = PackedVector3Array()
	for element in array:
		if not element is Vector3 and not len(element) == 3:
			push_error("Not a Vector3 array.")
		packed_vector3_array.append(Vector3(element[0], element[1], element[2]))
	return packed_vector3_array
	
	
static func convert_array_to_packed_vector2_array(array: Array) -> PackedVector2Array:
	var packed_vector3_array = PackedVector2Array()
	for element in array:
		if not element is Vector2 and not len(element) == 2:
			push_error("Not a Vector2 array.")
		packed_vector3_array.append(Vector2(element[0], element[1]))
	return packed_vector3_array


class MaterialData extends JsonSerializable:
	var index: int
	var type: String
	var name: String
	
	func to_json() -> String:
		return JSON.stringify(self.to_dict())
	
	func to_dict() -> Dictionary:
		return {
			"type": self.type,
			"index": self.index,
			"name": self.name,
		}


class DefaultMaterialData extends MaterialData:
	func _init(index: int):
		self.type = DEFAULT_MATERIAL_TYPE
		self.index = index
		self.name = "Default"


static func DefaultMaterialData_from_dict(dict: Dictionary) -> DefaultMaterialData:
	return DefaultMaterialData.new(
		dict.index
	)


class BasicMaterialData extends MaterialData:
	var color: Color
	
	func _init(
		index: int,
		name: String,
		color: Color
	):
		self.type = BASIC_MATERIAL_TYPE
		self.index = index
		self.name = name
		self.color = color
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"color": self.color
		})
		return dict
		
		
static func BasicMaterialData_from_dict(dict:Dictionary) -> BasicMaterialData:
	return BasicMaterialData.new(
		dict.index,
		dict.name,
		RawExport.convert_array_to_color(dict.color)
	)


class ImageTextureMaterialData extends MaterialData:
	var filenames: PackedStringArray
	
	#static func from_json(json: String) -> ImageTextureMaterialData:
	#	return ImageTextureMaterialData.new(1, "", PackedStringArray())
	
	func _init(
		index: int,
		name: String,
		filenames: PackedStringArray
	):
		self.type = IMAGE_FILES_MATERIAL_TYPE
		self.index = index
		self.name = name
		self.filenames = filenames
		
	func add_filename(filename: String) -> void:
		self.filenames.append(filename)
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"filenames": self.filenames
		})
		return dict
		
		
static func ImageTextureMaterialData_from_dict(dict: Dictionary) -> ImageTextureMaterialData:
	return ImageTextureMaterialData.new(
		dict.index,
		dict.name,
		dict.filenames
	)
		
		
class RawObjectData extends JsonSerializable:
	var vertices: PackedVector3Array
	var normals: PackedVector3Array
	var uvs: PackedVector2Array
	var indices: PackedInt32Array
	var material_indices: PackedInt64Array
	var material_data: Array[MaterialData]
	
	func _init(
		vertices := PackedVector3Array(),
		normals := PackedVector3Array(),
		uvs := PackedVector2Array(),
		indices := PackedInt32Array(),
		material_indices := PackedInt64Array(),
		material_data: Array[MaterialData] = Array()
	):
		self.vertices = RawExport.convert_array_to_packed_vector3_array(vertices)
		self.normals = RawExport.convert_array_to_packed_vector3_array(normals)
		self.uvs = RawExport.convert_array_to_packed_vector2_array(uvs)
		self.indices = indices
		self.material_indices = material_indices
		self.material_data = material_data
		
	func to_json() -> String:
		return JSON.stringify(self.to_dict())
		
	func to_dict() -> Dictionary:
		var material_data: Array[MaterialData] = []
		for material in self.material_data:
			material_data.append(material.to_dict())
		return {
			"vertices": self.vertices,
			"normals": self.normals,
			"uvs": self.uvs,
			"indices": self.indices,
			"material_indices": self.material_indices,
			"material_data": material_data
		}


static func RawObjectData_from_json(json_string: String) -> RawObjectData:
	var obj: Dictionary = JSON.parse_string(json_string)
	
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
	
	func _init(material_data_array: Array[RawExport.MaterialData]):
		self.material_data_array = material_data_array
	
	func get_materials() -> Array[Material]:
		var materials: Array[Material] = []
		
		for basetype_material_data in self.material_data_array:
			if basetype_material_data.type == BASIC_MATERIAL_TYPE:
				var material_data := basetype_material_data as BasicMaterialData
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
					print("adding normal texture:", normal_texture.resource_path)
					material.normal_texture = normal_texture
					material.normal_enabled = true
				#material.metallic = 0.0
				# material.roughness = 1.0
				#material.metallic_specular = 0.1
				materials.append(material)
			else:
				var material_data := basetype_material_data as DefaultMaterialData
				var material := StandardMaterial3D.new()
				material.albedo_color = Color(0.2, 0, 1)  # Blue
				materials.append(material)
				
		return materials
