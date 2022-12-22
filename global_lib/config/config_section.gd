extends RefCounted
class_name ConfigSection


var section: String
var config: Config


func _init(initial_file_path: String, initial_section: String) -> void:
	section = initial_section
	config = Config.new(initial_file_path)


func get_value(key: String, default: Variant) -> Variant:
	return config.get_value(section, key, default)


func set_value(key: String, value: Variant) -> void:
	config.set_value(section, key, value)
