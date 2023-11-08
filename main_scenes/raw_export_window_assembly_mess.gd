extends Node3D

### "imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay
### Dependencies:
# - RawExport4MeshLib.new_STris_from_file


const window_path: StringName =\
	"res://assets/parts/window_raw_export_test.rxm.json"
const decor_flat_spikes_path: StringName =\
	"res://assets/parts/window_decor_flat_spikes_raw_export_test.rxm.json"
const decor_nothing_path: StringName =\
	"res://assets/parts/window_decor_nothing_raw_export_test.rxm.json"

func _mess(show_debug_overlay) -> Array[Node3D]:
	var to_godot_space := true
	
	# Red needle: +X (Godot)
	Cavedig.needle(self, self.transform.translated(Vector3(3, 0, 0)), Vector3(1, 0, 0), 10.0, 0.02)
	# Blue needle with green disc: +Z (Godot) and +Y (Blender)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 0, 1), 10.0, 0.02)
	Cavedig.needle(self, self.transform.translated(Vector3(0, 0, 3)), Vector3(0, 1, 0), 0.05, 0.1)
	
	var window_surface_tris :=\
		RawExport4MeshLib.new_STris_from_file(window_path, to_godot_space)
	var decor_flat_spikes_surface_tris :=\
		RawExport4MeshLib.new_STris_from_file(decor_flat_spikes_path, to_godot_space)
	var decor_nothing_surface_tris :=\
		RawExport4MeshLib.new_STris_from_file(decor_nothing_path, to_godot_space)
		
	# Experimenting with merging meshes.
	window_surface_tris.add(decor_flat_spikes_surface_tris)
	window_surface_tris.tris.apply_all()
		
	var window_array_mesh_node := window_surface_tris.get_mesh_instance_3d()
	var decor_flat_spikes_array_mesh_node := decor_flat_spikes_surface_tris.get_mesh_instance_3d()
	var decor_nothing_array_mesh_node := decor_nothing_surface_tris.get_mesh_instance_3d()
	
	if show_debug_overlay:
		window_array_mesh_node.add_child(ADebugOverlay.new()
				.show_vertices(false)
				.show_normals(false)
				.visualize_arrays(
			window_surface_tris.tris.get_arrays()
		))
	
	
	return [
		window_array_mesh_node,
		#decor_flat_spikes_array_mesh_node
		#decor_nothing_array_mesh_node
	]


func _ready() -> void:
	for node in _mess(true):
		add_child(node)
