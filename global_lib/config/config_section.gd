extends RefCounted
class_name ConfigSection


var section: String
var config: Config


func _init(p_file_path: String, p_section: String) -> void:
	section = p_section
	config = Config.new(p_file_path)


func get_value(p_key: String, p_default: Variant) -> Variant:
	return config.get_value(section, p_key, p_default)


func set_value(p_key: String, p_value: Variant) -> void:
	config.set_value(section, p_key, p_value)
