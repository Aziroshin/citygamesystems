extends Node3D

var shader: ShaderMaterial = load("res://dev/cavedig/cavedig_material.tres")
@export var color: Vector3


func set_bone_component_material(
		component: GeometryInstance3D,
		material: ShaderMaterial
) -> void:
	component.material_override = material.duplicate()

func set_bone_component_color(
		component: GeometryInstance3D,
		color: Vector3
) -> void:
	component.material_override.set_shader_parameter("color", color)

func _ready() -> void:
	set_bone_component_material($Shaft, shader)
	set_bone_component_color($Shaft, color + Vector3(-0.1, -0.1, -0.1))
	
	set_bone_component_material($Head, shader)
	set_bone_component_color($Head, color + Vector3(0.1, 0.1, 0.1))
