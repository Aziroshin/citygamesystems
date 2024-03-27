extends Node3D
class_name WorldObject

# Dependencies:
# - CityBuilder.MultiPositioner
# - CityBuilder.OriginPositioner

signal collider_added(world_object: WorldObject, collider: CollisionObject3D)
signal collider_removed(collider: CollisionObject3D)


## Override in sub-class to initialize defaults if needed.
## Called before anything else in `._ready`.
## This makes @export variables without default values a bit more
## straightforward to manage.
func _set_defaults() -> void:
	pass


func _ready() -> void:
	_set_defaults()


# Intended to be overriden in a sub-class with a more appropriate implementation
# for the object in question.
func create_positioner() -> CityBuilder.MultiPositioner:
	var multi_positioner := CityBuilder.MultiPositioner.new()
	multi_positioner.add_positioner(CityBuilder.OriginPositioner.new(self))
	return multi_positioner

