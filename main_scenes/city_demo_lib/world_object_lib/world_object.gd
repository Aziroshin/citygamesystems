extends Node3D
class_name WorldObject

# Dependencies:
# - PositionerLib.MultiPositioner
# - PositionerLib.OriginPositioner

signal collider_added(world_object: WorldObject, collider: CollisionObject3D)
signal collider_removed(collider: CollisionObject3D)
@export var _colliders: Array[CollisionObject3D] = []
# The ID:
# IMPORTANT: Whatever is initializing the world object needs to make sure the ID
# is set before anything in the game is trying to read it, otherwise the game
# will crash once something tries to access it. This is intentionally left
# uninitialized, because errors in ID-initialization are too severe to be left
# to some obscured default behaviour (e.g. just setting it to 0 to prevent
# crashes on access).
## This ID represents the world object in the abstract. Other parts of the game
## may use this where directly referring to the object as seen at runtime isn't
## robust. Of course, it can also be used in general if that fits the game's
## architecture.
var id: int


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
## following classes, then it checks if they hold a reference to a
## `WorldObject` and returns it if that's the case:
##   - WorldObjectCharacterBody3D
##   - WorldObjectStaticBody3D
##   - WorldObjectArea3D
##   - WorldObjectRigidBody3D
## If it's none of those classes, it returns the value of the specific metadata
## key in `p_meta` on the collider if it's present . Will ignore this if `p_meta`
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
				var meta_value = p_collider.get_meta(p_meta)  # May return `null`.
				if meta_value is WorldObject:
					return meta_value
	
	return null


func get_colliders() -> Array[CollisionObject3D]:
	return _colliders


func add_collider(p_collider: CollisionObject3D) -> void:
	_colliders.append(p_collider)
	add_child(p_collider)
	collider_added.emit(self, p_collider)
