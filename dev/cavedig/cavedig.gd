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
	parent: Node3D,
	transform: Transform3D,
	color: Vector3 = Vector3(0.5, 0.5, 0.5),
	height: float = 10.0,
	radius: float = 0.05
) -> CSGCylinder3D:
	var shader = load("res://dev/cavedig/cavedig_material.tres")
	var debug_cylinder = CSGCylinder3D.new()
	parent.call_deferred("add_child", debug_cylinder)
	debug_cylinder.material_override = shader.duplicate()
	debug_cylinder.material_override.set_shader_parameter("color", color)
	debug_cylinder.height = height
	debug_cylinder.radius = radius
	debug_cylinder.global_transform = transform
	debug_cylinder.transform = transform
	
	return debug_cylinder

static func bone(
	parent: Node3D,
	transform: Transform3D,
	color: Vector3
) -> Node3D:
	var bone_scene: Node3D = Bone.instantiate()
	bone_scene.color = color
	parent.add_child(bone_scene)
	bone_scene.transform = transform
	return bone_scene

# Visualizes the bones of a Skeleton3D by adding an indicator for each bone,
# whereas each indicator gets the transform of the bone.
# The bigger end points away from the bone's origin.
# When executed on the same skeleton subsequently, the existing indicators get
# updated with their respective bone's current transform.
static func set_bone_indicators(skeleton: Skeleton3D):
	var indicator: Node3D

	# TODO: This is terribly inefficient. Better to add a Node3D that just has
	#   all the indicators in an array and check for that, then just modify all
	#   the transforms.
	for bone_idx in range(0, skeleton.get_bone_count()):
		var bone_transform: Transform3D = skeleton.get_bone_global_pose(bone_idx)
		var indicator_name := "bone_indicator_%s" % bone_idx
		var skeleton_children := skeleton.get_children()
		
		for skeleton_child in skeleton_children:
			if skeleton_child.name == indicator_name:
				skeleton_child.transform = bone_transform
				return
		
		indicator = Cavedig.bone(skeleton, bone_transform, Colors.AQUA)
		indicator.name = indicator_name
		
