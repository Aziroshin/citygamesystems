extends Node3D

var shader: ShaderMaterial = load("res://dev/cavedig/cavedig_material.tres")
@export var color: Vector3


func set_bone_component_material(
		p_component: GeometryInstance3D,
		p_material: ShaderMaterial
) -> void:
	p_component.material_override = p_material.duplicate()

func set_bone_component_color(
		p_component: GeometryInstance3D,
		p_color: Vector3
) -> void:
	p_component.material_override.set_shader_parameter("color", p_color)

func _ready() -> void:
	set_bone_component_material($Shaft, shader)
	set_bone_component_color($Shaft, color + Vector3(-0.1, -0.1, -0.1))
	
	set_bone_component_material($Head, shader)
	set_bone_component_color($Head, color + Vector3(0.1, 0.1, 0.1))
