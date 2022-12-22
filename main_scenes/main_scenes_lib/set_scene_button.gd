extends HBoxContainer

signal scene_picked

var initialized = false
var scene_resource_path: String = ""


func init(new_scene_resource_path: String, button_text: String) -> void:
	scene_resource_path = new_scene_resource_path
	$SetSceneButton.text = button_text
	initialized = true


func _on_set_scene_button_button_up() -> void:
	assert(initialized, "%s button_up signal emitted before call to init for this SceneItem."\
		% [$SetSceneButton.name])
	emit_signal("scene_picked", scene_resource_path)
