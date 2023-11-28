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
const decor_crown_path: StringName =\
	"res://assets/parts/window_decor_flat_spikes_crown_raw_export_test.rxm.json"

func _mess(p_show_debug_overlay) -> Array[Node3D]:
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
	var decor_crown_surface_tris :=\
		RawExport4MeshLib.new_STris_from_file(decor_crown_path, to_godot_space)
		
	# Merging two meshes that are specifically made to fit.
	window_surface_tris.add(decor_flat_spikes_surface_tris)
	
	# Now, experimenting with merging in a mesh that fits shape-wise, but not
	# geometrically, and that doesn't have its origin configured to fit with
	# the window.
	# Problem: The lighting doesn't fit.
	# Interesting read: https://godotforums.org/d/19920-godot-2-lighting-not-working-properly-in-manually-built-mesh/5
	decor_crown_surface_tris.tris.transform =\
		decor_crown_surface_tris.tris.transform.translated(Vector3(0.650898, 2.38575, 0.122625))
	decor_crown_surface_tris.tris.apply_transform()
	window_surface_tris.add(decor_crown_surface_tris)
			
	var window_array_mesh_node := window_surface_tris.get_mesh_instance_3d()
	var decor_crown_mesh_node := decor_crown_surface_tris.get_mesh_instance_3d()
	if p_show_debug_overlay:
		window_array_mesh_node.add_child(
			ADebugOverlay.new()
			.show_vertices(false)
			.show_normals(true)
			.visualize_arrays(window_surface_tris.tris.get_arrays())
		)
	return [ 
		window_array_mesh_node,
		#decor_crown_mesh_node
	]


func _ready() -> void:
	for node in _mess(false):
		add_child(node)
