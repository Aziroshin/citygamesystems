extends Node3D

const test_cube_path: StringName = "res://assets/parts/raw_export_test_cube.json"

func load_and_get_raw_export(path: String):
	pass

func load_and_get_test_cube() -> Resource:
	return load_and_get_raw_export(test_cube_path)

func _ready() -> void:
	var file := FileAccess.get_file_as_string(test_cube_path)
	var obj: Dictionary = JSON.parse_string(file)
	var object_data: RawExport.RawObjectData = RawExport.RawObjectData.from_json(file)
	print(object_data.to_json())
