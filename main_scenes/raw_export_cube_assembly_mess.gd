extends Node3D

### "imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay
### Dependencies:
# - RawExport4MeshLib.new_STris_from_file


const test_cube_path: StringName = "res://assets/parts/raw_export_test_cube.json"

func _mess(p_show_debug_overlay) -> Node3D:
	# Red needle: +X (Godot)
	Cavedig.needle(self, self.transform.translated(Vector3(3, 0, 0)), Vector3(1, 0, 0), 10.0, 0.02)
	# Blue needle with green disc: +Z (Godot) and +Y (Blender)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 0, 1), 10.0, 0.02)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 1, 0), 0.05, 0.1)
	
	# These two lines could be combined into a one-liner if it weren't for the
	# debug overlay.
	var surface_tris := RawExport4MeshLib.new_STris_from_file(test_cube_path)
	var array_mesh_node := surface_tris.get_mesh_instance_3d()
	
	if p_show_debug_overlay:
		array_mesh_node.add_child(ADebugOverlay.new().visualize_array_vertex(
			surface_tris.tris.get_arrays()
		))
	
	return array_mesh_node


func _ready() -> void:
	add_child(_mess(true))
