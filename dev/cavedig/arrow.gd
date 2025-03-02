extends MultiMesh
class_name CavedigMultiMeshSingleton

var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()


func _init() -> void:
	instance.multimesh = self
