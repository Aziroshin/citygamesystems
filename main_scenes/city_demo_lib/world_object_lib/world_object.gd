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
# for the world object in question.
func create_positioner() -> PositionerLib.MultiPositioner:
	var multi_positioner := PositionerLib.MultiPositioner.new()
	multi_positioner.add_positioner(PositionerLib.OriginPositioner.new(self))
	return multi_positioner


## Will return the `WorldObject` the specified collider in `p_collider` is
## associated with.
## Returns `null` if no association with a `WorldObject` can be determined.
##
## To determine it, it first checks if the collider is an instance of one of the
## following classes, then if they hold an initialized reference to a
## `WorldObject` and returns it if that's the case:
##   - WorldObjectCharacterBody3D
##   - WorldObjectStaticBody3D
##   - WorldObjectArea3D
##   - WorldObjectRigidBody3D
## If it's none of those classes, it returns the value of the specific metadata
## key in `p_meta` on the collider if it's present. Will ignore this if `p_meta`
## is an empty string (default).
static func get_from_collider_or_null(
	p_collider: Variant,
	p_meta: StringName = &""
) -> WorldObject:
	if p_collider is Node:
		if p_collider is WorldObjectCharacterBody3D:
			if (p_collider as WorldObjectCharacterBody3D).world_object:
				return (p_collider as WorldObjectCharacterBody3D).world_object
		elif p_collider is WorldObjectStaticBody3D:
			if (p_collider as WorldObjectStaticBody3D).world_object:
				return (p_collider as WorldObjectStaticBody3D).world_object
		elif p_collider is WorldObjectArea3D:
			if (p_collider as WorldObjectArea3D).world_object:
				return (p_collider as WorldObjectArea3D).world_object
		elif p_collider is WorldObjectRigidBody3D:
			if (p_collider as WorldObjectRigidBody3D).world_object:
				return (p_collider as WorldObjectRigidBody3D).world_object
		elif not p_meta == &"":
			if p_collider.has_meta(p_meta):
				# May return `null`.
				return p_collider.get_meta(p_meta)
			
	return null
