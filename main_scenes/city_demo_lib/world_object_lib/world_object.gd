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
# NOTE: If you change this default, change the documentation
# of `get_from_collider_or_null` and `add_collider` (both further below)
# accordingly.
## The default meta key name used to set/get the world object on colliders
## using `set_meta`/`get_meta`.
const DEFAULT_WORLD_OBJECT_META_KEY = &"world_object"


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
## If it's none of those classes, it returns the value of the specified metadata
## key in `p_meta` on the collider if it's present . Will ignore this if
## `p_meta` is set to an empty string.
## `p_meta` defaults to `DEFAULT_WORLD_OBJECT_META_KEY`, which
## defaults to `&"world_object"`.
static func get_from_collider_or_null(
	p_collider: Variant,
	p_meta: StringName = DEFAULT_WORLD_OBJECT_META_KEY
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


## Adds the specfied collider to the world object.
## If the collider is not of one of the following types, a metadata tag
## will be set on it with the world object as a value. `p_meta` is used
## as the key for this and defaults to `DEFAULT_WORLD_OBJECT_META_KEY`,
## which defaults to `&"world_object"`.
func add_collider(
	p_collider: CollisionObject3D,
	p_meta: StringName = DEFAULT_WORLD_OBJECT_META_KEY
) -> void:
	_colliders.append(p_collider)
	add_child(p_collider)
	
	if p_collider is WorldObjectCharacterBody3D:
		(p_collider as WorldObjectCharacterBody3D).world_object = self
	elif p_collider is WorldObjectStaticBody3D:
		(p_collider as WorldObjectStaticBody3D).world_object = self
	elif p_collider is WorldObjectArea3D:
		(p_collider as WorldObjectArea3D).world_object = self
	elif p_collider is WorldObjectRigidBody3D:
		(p_collider as WorldObjectRigidBody3D).world_object = self
	else:
		p_collider.set_meta(
			p_meta,
			self
		)
	
	collider_added.emit(self, p_collider)
