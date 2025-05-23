extends RefCounted
class_name Cavedig

const Bone: Resource = preload("res://dev/cavedig/bone.tscn")

const Colors: Dictionary = {
	RED = Vector3(1, 0, 0),
	ORANGE = Vector3(1, 0.2, 0),
	YELLOW = Vector3(0.7, 0.4, 0),
	GREEN = Vector3(0, 1, 0),
	SEA_GREEN = Vector3(0, 0.8, 0.3),
	CERULEAN = Vector3(0, 0.3, 0.8),
	AQUA = Vector3(0, 0.7, 0.7),
	BLUE = Vector3(0, 0, 1)
}


static func needle(
	p_parent: Node3D,
	p_transform: Transform3D,
	p_color: Vector3 = Vector3(0.5, 0.5, 0.5),
	p_height: float = 10.0,
	p_radius: float = 0.05,
	p_hidden := false
) -> CSGCylinder3D:
	var shader = load("res://dev/cavedig/cavedig_material.tres")
	var debug_cylinder = CSGCylinder3D.new()
	p_parent.call_deferred("add_child", debug_cylinder)
	debug_cylinder.material_override = shader.duplicate()
	debug_cylinder.material_override.set_shader_parameter("color_a", p_color)
	debug_cylinder.material_override.set_shader_parameter("color_b", p_color)
	debug_cylinder.height = p_height
	debug_cylinder.radius = p_radius
	debug_cylinder.transform = p_transform
	if p_hidden:
		debug_cylinder.hide()
	
	return debug_cylinder


static func needle_between(
	p_parent: Node3D,
	p_from: Vector3,
	p_to: Vector3,
	p_color: Vector3 = Vector3(0.5, 0.5, 0.5),
	p_radius: float = 0.05,
	p_hidden := false
) -> CSGCylinder3D:
	var vector := (p_to - p_from)
	
	var basis_x := vector.normalized().cross(Vector3(0.0, 1.0, 0.0))
	var basis_y := vector.normalized()
	var basis_z := basis_x.cross(basis_y)
	
	var cylinder := needle(
		p_parent,
		Transform3D(
			Basis(
				basis_x,
				basis_y,
				basis_z,
			),
			p_from + vector * 0.5
		),
		p_color,
		vector.length(),
		p_radius,
		p_hidden
	)
	
	return cylinder


static func bone(
	p_parent: Node3D,
	p_transform: Transform3D,
	p_color: Vector3
) -> Node3D:
	var bone_scene: Node3D = Bone.instantiate()
	bone_scene.color = p_color
	p_parent.add_child(bone_scene)
	bone_scene.transform = p_transform
	return bone_scene

# Visualizes the bones of a Skeleton3D by adding an indicator for each bone,
# whereas each indicator gets the transform of the bone.
# The bigger end points away from the bone's origin.
# When executed on the same skeleton subsequently, the existing indicators get
# updated with their respective bone's current transform.
static func set_bone_indicators(p_skeleton: Skeleton3D):
	var indicator: Node3D

	# TODO: This is terribly inefficient. Better to add a Node3D that just has
	#   all the indicators in an array and check for that, then just modify all
	#   the transforms.
	for bone_idx in range(0, p_skeleton.get_bone_count()):
		var bone_transform: Transform3D = p_skeleton.get_bone_global_pose(bone_idx)
		var indicator_name := "bone_indicator_%s" % bone_idx
		var skeleton_children := p_skeleton.get_children()
		
		for skeleton_child in skeleton_children:
			if skeleton_child.name == indicator_name:
				skeleton_child.transform = bone_transform
				return
		
		indicator = Cavedig.bone(p_skeleton, bone_transform, Colors.AQUA)
		indicator.name = indicator_name
