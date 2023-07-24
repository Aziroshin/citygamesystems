@tool
extends Node3D

### "Imports": MeshLib
const ATwoSidedRoof := CityMeshLib.ATwoSidedRoof
### "Imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay


func _mess_ASideRoof(show_debug_overlay) -> Node3D:
	
	var side_roof := ATwoSidedRoof.new(
		PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0.5, -0.5), Vector3(0, 0, -1)]),
		PackedVector3Array([Vector3(1, 0, 0), Vector3(1, 1, -0.5), Vector3(1, 0, -1)]),
		PackedVector3Array([Vector3(0, 0, 0), Vector3(0.25, 0, 0), Vector3(0.75, 0 ,0), Vector3(1, 0, 0)]),
		PackedVector3Array([Vector3(0, 0, -1), Vector3(0.25, 0, -1), Vector3(0.75, 0, -1), Vector3(1, 0, -1)])
	)
	var side_roof_mesh := CityGeoFuncs.get_array_mesh_node_from_vertices(side_roof.get_array_vertex())
	
	if show_debug_overlay:
		side_roof_mesh.add_child(ADebugOverlay.new().visualize_array_vertex(side_roof.get_array_vertex()))
	return side_roof_mesh
	
	
func _ready() -> void:
	add_child(_mess_ASideRoof(true))
