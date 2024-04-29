extends Node3D
class_name StreetToolMapPreviewer

# Dependencies:
# - StreetMesh

var _preview_mesh := MeshInstance3D.new()

@export var map_agent: ToolLibMapAgent


func _on_previewable_change(
	p_map_points: PackedVector3Array,
	p_transforms: Array[Transform3D],
	p_profile2d: PackedVector2Array,
) -> void:
	print("LALA")
	map_agent.get_map_node().remove_child(_preview_mesh)
	_preview_mesh = StreetMesh.create_network_segment(
		p_map_points,
		p_transforms,
		p_profile2d
	)
	map_agent.get_map_node().add_child(_preview_mesh)

