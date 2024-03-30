extends WorldObjectLifeCycler
class_name CityGameWorldObjectLifeCycler

@export var collider_manager: ColliderManager


func register_world_object(p_world_object: WorldObject) -> void:
	p_world_object.collider_added.connect(collider_manager._on_collider_added)
	p_world_object.collider_removed.connect(collider_manager._on_collider_removed)


func unregister_world_object(p_world_object: WorldObject) -> void:
	p_world_object.collider_added.disconnect(collider_manager._on_collider_added)
	p_world_object.collider_removed.disconnect(collider_manager._on_collider_removed)


func _init(p_collider_manager: ColliderManager):
	assert(p_collider_manager, "Collider manager passed to _init is null.")
	collider_manager = p_collider_manager


func _ready() -> void:
	if not collider_manager:
		collider_manager = get_node(CityGameGlobals.NodeNames.CGS_COLLIDER_MANAGER)
	push_warning(collider_manager, "There is no collider manager.")
