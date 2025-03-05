extends Resource
class_name CavedigMultiMeshInstanceManager3D

var instance := MultiMeshInstance3D.new()
@export var mesh: Mesh:
	set(p_value):
		mesh = p_value
		_ensure_multi_mesh()
		instance.multimesh.mesh = p_value
@export var material: ShaderMaterial:
	set(p_value):
		material = p_value
		_ensure_multi_mesh()
		instance.multimesh.mesh.surface_set_material(0, p_value)
var transforms: Array[Transform3D] = []


func _init(
	p_mesh: Mesh = null,
	p_material: ShaderMaterial = null
) -> void:
	_ensure_multi_mesh()
	if not p_mesh == null:
		mesh = p_mesh
		
	if instance.multimesh.mesh == null:
		push_error("Cavedig: No mesh specified for multi-mesh instance.")
		
	if not p_material == null:
		material = p_material
		
	instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D


func add_instance(
	p_transform: Transform3D
) -> int:
	transforms.append(p_transform)
	return transforms.size() - 1


func bake() -> void:
	instance.multimesh.instance_count = transforms.size()
	var i := 0
	for transform in transforms:
		instance.multimesh.set_instance_transform(i, transform)
		i += 1


func _ensure_multi_mesh() -> void:
	if instance.multimesh == null:
		instance.multimesh = MultiMesh.new() 
