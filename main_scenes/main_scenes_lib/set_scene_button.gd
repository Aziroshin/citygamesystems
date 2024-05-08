extends HBoxContainer

signal scene_picked

var initialized = false
var scene_resource_path: String = ""


func init(p_new_scene_resource_path: String, p_button_text: String) -> void:
	scene_resource_path = p_new_scene_resource_path
	$SetSceneButton.text = p_button_text
	initialized = true


func _on_set_scene_button_button_up() -> void:
	assert(initialized, "%s button_up signal emitted before call to init for this SceneItem."\
		% [$SetSceneButton.name])
	emit_signal("scene_picked", scene_resource_path)
	$SetSceneButton.release_focus()
