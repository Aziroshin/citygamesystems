extends RefCounted
class_name RawExport4MeshLib

### "Imports": MeshLib
const STris := MeshLib.STris
const AFlushingMultiTri := MeshLib.AFlushingMultiTri
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
	p_path: String,
	p_dbg_apply_fixes = true
) -> STris:
	assert(FileAccess.file_exists(p_path), "File doesn't exist: %s" % p_path)
	return new_STris_from_JSON(
		FileAccess.get_file_as_string(p_path),
		p_dbg_apply_fixes
	)
	
	
static func new_STris_from_JSON(
	p_json: String,
	p_dbg_apply_fixes = true
) -> STris:
	return new_STris_from_RawObjectData(
		RawExport.RawObjectData_from_json(p_json),
		p_dbg_apply_fixes
	)
	
	
static func new_STris_from_RawObjectData(
	p_raw_object_data: RawObjectData,
	p_dbg_apply_fixes = true,
	# TODO: Better typing once it's possible.
	# TODO: This actually doesn't work - passing the class causes a type error.
	p_ResolverClass := BasicMaterialResolver,
) -> STris:
	var vertices := p_raw_object_data.vertices
	var normals := p_raw_object_data.normals
	var uvs := p_raw_object_data.uvs
	
	if not len(vertices) % 3 == 0:
		push_error(
			"Attempted to initialize `STris` from a list of vertices not"
			+ "divisible by 3."
		)
		
	var multi_tri := AFlushingMultiTri.new()
	for i_face in range(len(vertices) / 3.0):
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
	if p_dbg_apply_fixes:
		multi_tri.add_modifier(MYFlipUVs.new())
		multi_tri.add_modifier(MYUp.new())
		multi_tri.add_modifier(MFlipVerticesX.new())
		multi_tri.add_modifier(MInvertSurfaceArrays.new())
	multi_tri.apply_all()
	
	var resolver := p_ResolverClass.new(p_raw_object_data.material_data)
	if not resolver is MaterialResolver:
		var err_msg := "TypeError: 'ResolverClass' does not extend 'MaterialResolver'."
		push_error(err_msg)
		assert(false, err_msg)
	return STris.new(
		multi_tri,
		p_raw_object_data.material_indices,
		resolver.get_materials()
	)
