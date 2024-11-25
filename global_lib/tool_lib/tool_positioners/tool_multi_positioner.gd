extends ToolLibToolPositioner
class_name ToolLibToolMultiPositioner

var positioners: Array[ToolLibToolPositioner] = []


func _ready() -> void:
	for child in get_children():
		positioners.append(child)
