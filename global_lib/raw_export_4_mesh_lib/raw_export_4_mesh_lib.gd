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
const MaterialResolver := RawExport.MaterialResolver
# Used: RawExport.RawObjectData_from_json


static func new_STris_from_file(
	path: String,
	_dbg_apply_fixes = true
) -> STris:
	assert(FileAccess.file_exists(path), "File doesn't exist: %s" % path)
	return new_STris_from_JSON(
		FileAccess.get_file_as_string(path),
		_dbg_apply_fixes
	)
	
	
static func new_STris_from_JSON(
	json: String,
	_dbg_apply_fixes = true
) -> STris:
	return new_STris_from_RawObjectData(
		RawExport.RawObjectData_from_json(json),
		_dbg_apply_fixes
	)
	
	
static func new_STris_from_RawObjectData(
	raw_object_data: RawObjectData,
	_dbg_apply_fixes = true,
	# TODO: Better typing once it's possible.
	# TODO: This actually doesn't work - passing the class causes a type error.
	ResolverClass := BasicMaterialResolver,
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
	if _dbg_apply_fixes:
		multi_tri.add_modifier(MYFlipUVs.new())
		multi_tri.add_modifier(MYUp.new())
		multi_tri.add_modifier(MFlipVerticesX.new())
		multi_tri.add_modifier(MInvertSurfaceArrays.new())
	multi_tri.apply_all()
	
	var resolver := ResolverClass.new(raw_object_data.material_data)
	if not resolver is MaterialResolver:
		var err_msg := "TypeError: 'ResolverClass' does not extend 'MaterialResolver'."
		push_error(err_msg)
		assert(false, err_msg)
	return STris.new(
		multi_tri,
		raw_object_data.material_indices,
		resolver.get_materials()
	)
