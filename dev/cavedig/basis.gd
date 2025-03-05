extends Node3D
class_name CavedigTransform3DVisualizer

var x_arrow_multi_mesh: CavedigMultiMeshInstanceManager3D
var y_arrow_multi_mesh: CavedigMultiMeshInstanceManager3D
var z_arrow_multi_mesh: CavedigMultiMeshInstanceManager3D
var point_multi_mesh: CavedigMultiMeshInstanceManager3D

const FALLBACK_DEFAULT_LENGTH := Vector3(1.0, 1.0, 1.0)
const FALLBACK_DEFAULT_CIRCUMFERENCE := Vector3(1.0, 1.0, 1.0)
var initialized_default_length := FALLBACK_DEFAULT_LENGTH
var initialized_default_circumference := FALLBACK_DEFAULT_CIRCUMFERENCE


func _init(
	p_parent: Node3D,
	p_color := Color(),
	p_length := FALLBACK_DEFAULT_LENGTH ,
	p_circumference := FALLBACK_DEFAULT_CIRCUMFERENCE,
	p_hidden := false,
	p_material: ShaderMaterial = null,
) -> void:
	var template_material: ShaderMaterial
	var arrow_template_mesh := preload("res://dev/cavedig/arrow_Arrow.res")
	var point_template_mesh := preload("res://dev/cavedig/point_Point.res")
	if p_material == null:
		template_material = preload("res://dev/cavedig/cavedig_material.tres")
	else:
		template_material = p_material
		
	x_arrow_multi_mesh = CavedigMultiMeshInstanceManager3D.new(
		arrow_template_mesh.duplicate(),
		template_material.duplicate()
	)
	x_arrow_multi_mesh.material.set_shader_parameter(&"color_a", p_color)
	x_arrow_multi_mesh.material.set_shader_parameter(&"color_b", Vector3(1.0, 0.0, 0.0))
	self.add_child(x_arrow_multi_mesh.instance)
	
	y_arrow_multi_mesh = CavedigMultiMeshInstanceManager3D.new(
		arrow_template_mesh.duplicate(),
		template_material.duplicate()
	)
	y_arrow_multi_mesh.material.set_shader_parameter(&"color_a", p_color)
	y_arrow_multi_mesh.material.set_shader_parameter(&"color_b", Vector3(0.0, 1.0, 0.0))
	self.add_child(y_arrow_multi_mesh.instance)
	
	z_arrow_multi_mesh = CavedigMultiMeshInstanceManager3D.new(
		arrow_template_mesh.duplicate(),
		template_material.duplicate()
	)
	z_arrow_multi_mesh.material.set_shader_parameter(&"color_a", p_color)
	z_arrow_multi_mesh.material.set_shader_parameter(&"color_b", Vector3(0.0, 0.0, 1.0))
	self.add_child(z_arrow_multi_mesh.instance)
	
	point_multi_mesh = CavedigMultiMeshInstanceManager3D.new(
		point_template_mesh.duplicate(),
		template_material.duplicate()
	)
	point_multi_mesh.material.set_shader_parameter(&"color_a", p_color)
	point_multi_mesh.material.set_shader_parameter(&"color_b", p_color)
	self.add_child(point_multi_mesh.instance)
	
	p_parent.add_child(self)


## Add a `Transform3D` to be visualized.
## `p_length` and `p_circumference` will be applied to the visualizing arrows.
## Only positive values are supported for `p_length` and `p_circumference`.
## If either are `Vector3(-1.0, -1.0, -1.0)` (the default), the corresponding
## values are going to be initialized from `.initialized_default_length` or 
## `.initialized_default_circumference` respectively.
##
## Note: Don't forget to call `bake` once you're done adding transforms.
func add(
	p_transform: Transform3D,
	p_length := Vector3(-1.0, -1.0, -1.0),
	p_circumference := Vector3(-1, -1, -1),
) -> int:
	var length := initialized_default_length if p_length == Vector3(-1, -1, -1)\
	else p_length
	
	var circumference := initialized_default_circumference if p_circumference == Vector3(-1, -1, -1)\
	else p_circumference
	#region Point
	var largest_circumference: float = max(circumference.x, circumference.y, circumference.z)
	var basis_p := Basis.looking_at(p_transform.basis.z)
	basis_p = basis_p * Basis.from_scale(Vector3(
		largest_circumference,
		largest_circumference,
		largest_circumference
	))
	point_multi_mesh.add_instance(Transform3D(basis_p, p_transform.origin))
	#endregion
	
	#region Arrows
	var basis_y := Basis.looking_at(p_transform.basis.y * length.y)
	basis_y = basis_y * Basis.from_scale(Vector3(circumference.y, circumference.y, length.y))
	y_arrow_multi_mesh.add_instance(Transform3D(basis_y, p_transform.origin))
	
	var basis_x := Basis.looking_at(p_transform.basis.x * length.x, basis_y.y)
	basis_x = basis_x * Basis.from_scale(Vector3(circumference.x, circumference.x, length.x))
	x_arrow_multi_mesh.add_instance(Transform3D(basis_x, p_transform.origin))
	
	var basis_z := Basis.looking_at(p_transform.basis.z * length.z)
	basis_z = basis_z * Basis.from_scale(Vector3(circumference.z, circumference.z, length.z))
	
	# Assuming the point count is identical to the arrow counts.
	return z_arrow_multi_mesh.add_instance(Transform3D(basis_z, p_transform.origin))
	#endregion


## Add multiple `Transform3D`s by array.
## `p_lengths` and `p_circumferences` are evaluated until they reach their
## end, or until `p_transforms` reaches its end. If there are fewer lengths
## or circumferences than transforms, the last length or circumference in their
## respective arrays will be applied for the remaining transforms.
## If `p_length` or `p_circumference` are empty, `.default_length` or
## `.default_circumference` will be used respectively.
## Reference the documentation for `add` for further information.
##
## Note: Don't forget to call `bake` once you're done adding transforms.
func add_array(
	p_transforms: Array[Transform3D],
	p_lengths: Array[Vector3] = [],
	p_circumferences: Array[Vector3] = []
) -> void:
	var i_transform := 0
	var length := FALLBACK_DEFAULT_LENGTH
	var circumference := FALLBACK_DEFAULT_CIRCUMFERENCE
	for _transform in p_transforms:
		if i_transform < p_lengths.size():
			length = p_lengths[i_transform]
		if i_transform < p_circumferences.size():
			circumference = p_circumferences[i_transform]
		
		add(_transform, length, circumference)
		
		i_transform += 1


func bake() -> CavedigTransform3DVisualizer:
	x_arrow_multi_mesh.bake()
	y_arrow_multi_mesh.bake()
	z_arrow_multi_mesh.bake()
	point_multi_mesh.bake()
	return self


func reset() -> void:
	x_arrow_multi_mesh.instance.multimesh.instance_count = 0
	x_arrow_multi_mesh.transforms.clear()
	y_arrow_multi_mesh.instance.multimesh.instance_count = 0
	y_arrow_multi_mesh.transforms.clear()
	z_arrow_multi_mesh.instance.multimesh.instance_count = 0
	z_arrow_multi_mesh.transforms.clear()
	point_multi_mesh.instance.multimesh.instance_count = 0
	point_multi_mesh.transforms.clear()
