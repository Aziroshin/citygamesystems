extends Area3D
class_name IndexedAreaToolCollider

var hints: Array[CityGameDefaults.ColliderHints]
var index := 0


func _init(
	p_tool: Node,
	p_shape: Shape3D,
	p_index: int,
	p_hints: Array[CityGameDefaults.ColliderHints] = [],
) -> void:
	index = p_index
	hints = p_hints
	
	var collision_shape_3d := CollisionShape3D.new()
	collision_shape_3d.shape = p_shape
	self.add_child(collision_shape_3d)
