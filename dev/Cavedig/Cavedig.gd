extends Reference
class_name Cavedig

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
	parent: Node,
	position: Vector3,
	color: Vector3 = Vector3(0.5, 0.5, 0.5),
	height: float = 10.0,
	radius: float = 0.05
) -> CSGCylinder:
	var shader = load("res://dev/visualization/VisualizationShader.tres")
	var debug_cylinder = CSGCylinder.new()
	parent.call_deferred("add_child", debug_cylinder)
	debug_cylinder.material_override = shader.duplicate()
	debug_cylinder.material_override.set_shader_param("color", color)
	debug_cylinder.height = height
	debug_cylinder.radius = radius
	debug_cylinder.global_transform.origin = position
	
	return debug_cylinder
