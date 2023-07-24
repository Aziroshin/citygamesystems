@tool
extends Node3D

### "Imports": MeshLib
const AHorizontallyFoldedPlane := MeshLib.AHorizontallyFoldedPlane

### "Imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay


class AMultiPitchedQuadRoof extends AHorizontallyFoldedPlane:
	pass
	
	
func _mess_AMultiPitchedQuadRoof() -> Node3D:
	### BEGIN: Test` AMultiPitchedQuadRoof`
#	var left_side: PackedVector3Array = [bottom_left, top_left, top_left + Vector3(0, 1, 0), top_left + Vector3(0, 2, 0)]
#	var right_side: PackedVector3Array = [bottom_right, top_right, top_right + Vector3(0, 1, 0), top_right + Vector3(0, 2, 0)]
	var left_side := CityGeoFuncs.create_kinked_roof_line(Vector3(), Vector3(0, 1, -1), 1, 1.0, 0.8)
	var right_side := PackedVector3Array()
	for vertex in left_side:
		right_side.append(vertex + Vector3(1, 0, 0))
		
	var roof := AMultiPitchedQuadRoof.new(
		left_side,
		right_side
	)
	roof.apply_all()
	var roof_surface_arrays := []
	roof_surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	var roof_surface_array_vertex := roof.get_array_vertex()
	roof_surface_arrays[ArrayMesh.ARRAY_VERTEX] = roof_surface_array_vertex
	
	#roof.add_child(GeoFuncs.get_array_mesh_node(roof_surface_arrays))
	
#	var quad_surface_array := []
#	quad_surface_array.resize(ArrayMesh.ARRAY_MAX)
#	quad_surface_array[ArrayMesh.ARRAY_VERTEX] = quad.get_array_vertex()
	
	#roof.add_child(GeoFuncs.get_array_mesh_node(quad_surface_array))
	
	### END: Test `AMultiPitchedQuadRoof`
	
	return CityGeoFuncs.get_array_mesh_node(roof_surface_arrays)
	
	
func _ready() -> void:
	add_child(_mess_AMultiPitchedQuadRoof())
