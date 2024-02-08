extends TextureButton
class_name TextureButtonWithStaticBackground

var background_texture_rect := TextureRect.new()
@export var background_texture: Texture2D:
	get:
		return background_texture_rect.texture
	set(p_value):
		background_texture_rect.texture = p_value

func _ready():
	background_texture_rect.show_behind_parent = true
	add_child(background_texture_rect)
	
