extends ToolLibToolActivatorAgent
class_name ToolLibTextureButtonToolActivatorAgent


@export var texture_button: TextureButton
@export var active_texture: Texture2D
@export var inactive_texture: Texture2D


func _set_activator_to_active() -> void:
	if texture_button and active_texture:
		texture_button.texture_normal = active_texture


func _set_activator_to_inactive() -> void:
	if texture_button and inactive_texture:
		texture_button.texture_normal = inactive_texture
