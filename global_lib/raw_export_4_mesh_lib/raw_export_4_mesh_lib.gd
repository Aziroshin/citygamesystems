extends RefCounted
class_name RawExport4MeshLib

### "Imports": MeshLib
const STris := MeshLib.STris
const AMultiTri := MeshLib.AMultiTri
const ATri := MeshLib.ATri
const MYFlipUVs := MeshLib.MYFlipUVs
const MYUp := MeshLib.MYUp
const MFlipVerticesX := MeshLib.MFlipVerticesX
const MInvertSurfaceArrays := MeshLib.MInvertSurfaceArrays
### "Imports": RawExport
const RawObjectData := RawExport.RawObjectData
const BasicMaterialResolver := RawExport.BasicMaterialResolver
# Used: RawExport.RawObjectData_from_json


static func new_STris_from_file(
	path: String
) -> STris:
	return new_STris_from_JSON(
		FileAccess.get_file_as_string(path)
	)


static func new_STris_from_JSON(
	json: String
) -> STris:
	return new_STris_from_RawObjectData(
		RawExport.RawObjectData_from_json(json)
	)


static func new_STris_from_RawObjectData(
	raw_object_data: RawObjectData
) -> STris:
	var vertices := raw_object_data.vertices
	var normals := raw_object_data.normals
	var uvs := raw_object_data.uvs
	
	var multi_tri = AMultiTri.new()
	for i_face in range(len(vertices) / 3):
		var offset := i_face * 3
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
	
	return STris.new(
		multi_tri,
		raw_object_data.material_indices,
		BasicMaterialResolver.new(raw_object_data.material_data).get_materials()
	)
