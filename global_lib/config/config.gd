extends RefCounted
class_name Config

var file_path: String
var config: ConfigFile


func _init(p_file_path: String) -> void:
	file_path = p_file_path
	config = ConfigFile.new()
	
	var dir := DirAccess.open(file_path.get_base_dir())
	if not dir.file_exists(file_path):
		config.save(file_path)
	config.load(p_file_path)


func get_value(p_section: String, p_key: String, p_default: Variant) -> Variant:
	return config.get_value(p_section, p_key, p_default)


func set_value(p_section: String, p_key: String, p_value: Variant) -> void:
	config.set_value(p_section, p_key, p_value)
	config.save(file_path)
