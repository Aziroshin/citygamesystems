extends Node3D
class_name WorldObject

# Dependencies:
# - PositionerLib.MultiPositioner
# - PositionerLib.OriginPositioner

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
func create_positioner() -> PositionerLib.MultiPositioner:
	var multi_positioner := PositionerLib.MultiPositioner.new()
	multi_positioner.add_positioner(PositionerLib.OriginPositioner.new(self))
	return multi_positioner

