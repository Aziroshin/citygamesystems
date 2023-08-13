extends RefCounted
class_name RawExport


const DEFAULT_MATERIAL_TYPE = "DEFAULT"
const BASIC_MATERIAL_TYPE = "BASIC"
const IMAGE_FILES_MATERIAL_TYPE = "IMAGE_FILES"


static func convert_array_to_color(array: Array) -> Color:
	if len(array) == 3:
		return Color(array[0], array[1], array[2])
		
	return Color(array[0], array[1], array[2], array[3])

static func convert_array_to_packed_vector3_array(array: Array) -> PackedVector3Array:
	var packed_vector3_array = PackedVector3Array()
	if not len(packed_vector3_array) == 3:
		push_error("Not a Vector3 array.")
	for element in array:
		packed_vector3_array.append(Vector3(element[0], element[1], element[2]))
	return packed_vector3_array
	
static func convert_array_to_packed_vector2_array(array: Array) -> PackedVector2Array:
	var packed_vector3_array = PackedVector2Array()
	if not len(packed_vector3_array) == 2:
		push_error("Not a Vector2 array.")
	for element in array:
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

	static func from_dict(dict: Dictionary) -> DefaultMaterialData:
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
		
	static func from_dict(dict:Dictionary) -> BasicMaterialData:
		return BasicMaterialData.new(
			dict.index,
			dict.name,
			RawExport.convert_array_to_color(dict.color)
		)
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"color": self.color
		})
		return dict

class ImageTextureMaterialData extends MaterialData:
	var filenames: PackedStringArray
	
#	static func from_json(json: String) -> ImageTextureMaterial:
#		return ImageTextureMaterial.new(1, "", PackedStringArray())
	
	func _init(
		index: int,
		name: String,
		filenames: PackedStringArray
	):
		self.type = IMAGE_FILES_MATERIAL_TYPE
		self.index = index
		self.name = name
		self.filenames = filenames
		
	func add_file_name(filename: String) -> void:
		self.filenames.append(filename)
		
	static func from_dict(dict: Dictionary) -> ImageTextureMaterialData:
		return ImageTextureMaterialData.new(
			dict.index,
			dict.name,
			dict.filenames
		)
		
	func to_dict() -> Dictionary:
		var dict := super()
		dict.merge({
			"filenames": self.filenames
		})
		return dict
		
		
class RawObjectData extends JsonSerializable:
	var vertices: PackedVector3Array
	var normals: PackedVector3Array
	var uvs: PackedVector2Array
	var indices: PackedInt64Array
	var material_indices: PackedInt64Array
	var materials: Array
	
	func _init(
		vertices := PackedVector3Array(),
		normals := PackedVector3Array(),
		uvs := PackedVector2Array(),
		indices := PackedInt64Array(),
		material_indices := PackedInt64Array(),
		materials := Array()
	):
		self.vertices = RawExport.convert_array_to_packed_vector3_array(vertices)
		self.normals = RawExport.convert_array_to_packed_vector3_array(normals)
		self.uvs = RawExport.convert_array_to_packed_vector2_array(uvs)
		self.indices = indices
		self.material_indices = material_indices
		self.materials = materials
		
	func to_json() -> String:
		return JSON.stringify(self.to_dict())
		
	static func from_json(json_string: String) -> RawObjectData:
		var obj: Dictionary = JSON.parse_string(json_string)
		
		var materials = Array()
		for material in obj.materials:
			if material.type == DEFAULT_MATERIAL_TYPE:
				materials.append(DefaultMaterialData.from_dict(material))
			elif material.type == BASIC_MATERIAL_TYPE:
				materials.append(BasicMaterialData.from_dict(material))
			elif material.type == IMAGE_FILES_MATERIAL_TYPE:
				materials.append(ImageTextureMaterialData.from_dict(material))
		
		return RawObjectData.new(
			RawExport.convert_array_to_packed_vector3_array(obj.vertices),
			RawExport.convert_array_to_packed_vector3_array(obj.normals),
			RawExport.convert_array_to_packed_vector2_array(obj.uvs),
			obj.indices,
			obj.material_indices,
			materials
		)
		
	func to_dict() -> Dictionary:
		var materials := Array()
		for material in self.materials:
			materials.append(material.to_dict())
		return {
			"vertices": self.vertices,
			"normals": self.normals,
			"uvs": self.uvs,
			"indices": self.indices,
			"material_indices": self.material_indices,
			"materials": materials
		}
