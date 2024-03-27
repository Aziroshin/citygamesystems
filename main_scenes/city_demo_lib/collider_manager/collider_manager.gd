extends Node
class_name ColliderManager

var _world_objects_by_colliders := Dictionary()


func _on_collider_added(p_world_object: WorldObject, p_collider: CollisionObject3D):
	_world_objects_by_colliders[p_collider] = p_world_object


func _on_collider_removed(p_collider: CollisionObject3D):
	_world_objects_by_colliders.erase(p_collider)


func get_world_object_by_collider(p_collider: CollisionObject3D) -> WorldObject:
	return _world_objects_by_colliders[p_collider]
