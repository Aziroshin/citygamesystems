extends RefCounted
class_name Config

var file_path: String
var config: ConfigFile


func _init(initial_file_path: String) -> void:
	file_path = initial_file_path
	config = ConfigFile.new()
	
	var dir := DirAccess.open(file_path.get_base_dir())
	if not dir.file_exists(file_path):
		config.save(file_path)
	config.load(initial_file_path)


func get_value(section: String, key: String, default: Variant) -> Variant:
	return config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	config.save(file_path)
