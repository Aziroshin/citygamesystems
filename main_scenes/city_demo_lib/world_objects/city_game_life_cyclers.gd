extends WorldObjectLifeCyclers
class_name CityGameWorldObjectLifeCyclers

@export var collider_manager: ColliderManager
@onready var layout := LayoutWorldObjectLifeCycler.new(collider_manager)


func _enter_tree() -> void:
	assert(collider_manager, "No collider_manager defined for node %s." % get_name())

