extends ToolLibToolMapPositioner
class_name ToolLibToolCollidingPositioner

var colliding_objects := CollisionObjects.new()
var reference_position := Vector3():
	get:
		return reference_position
	set(p_value):
		reference_position = p_value
		collider.transform.origin = p_value
var position := Vector3()
var position_getting_status := PositionGettingStatus.new()
## Will be used for the default SphereShape3D if no collider override is
## specified.
@export var default_collider_radius := 0.5
## Optional Shape3D to detect collisions with snappable objects. If none is
## specified, a SphereShape3D with the default radius will be used.
@export var shape_override: Shape3D
@onready var collider := Area3D.new()


class CollisionObjects:
	var _objects: Dictionary = {}
	var count_ro: int:
		get:
			return len(_objects.values())
		set(p_value):
			push_error("Tried setting read-only value.")
	
	func add(p_object: CollisionObject3D) -> CollisionObject3D:
		_objects[p_object.get_instance_id()] = p_object
		return p_object
	
	
	func remove(p_object: CollisionObject3D) -> CollisionObject3D:
		_objects.erase(p_object.get_instance_id())
		return p_object
	
	
	func get_all() -> Array[CollisionObject3D]:
		# For some reason, this doesn't work:
		#return _objects.values() as Array[CollisionObject3D]
		# So we're doing this (for now?):
		var typed_objects: Array[CollisionObject3D] = []
		for object in _objects.values():
			typed_objects.append(object)
		return typed_objects
		
		
	func get_first() -> CollisionObject3D:
		return _objects.values()[0]


func is_colliding() -> bool:
	if colliding_objects.count_ro > 0:
		return true
	else:
		return false


func _create_default_shape_3d() -> Shape3D:
	var shape := SphereShape3D.new()
	shape.radius = default_collider_radius
	return shape


func _create_collision_shape_3d(p_shape: Shape3D) -> CollisionShape3D:
	var collision_shape_3d := CollisionShape3D.new()
	collision_shape_3d.shape = p_shape
	return collision_shape_3d


func _ready() -> void:
	super()
	if not shape_override:
		collider.add_child(_create_collision_shape_3d(_create_default_shape_3d()))
	else:
		collider.add_child(_create_collision_shape_3d(shape_override))
	collider.input_ray_pickable = false
	map_agent.get_map_node().add_child(collider)
	collider.area_entered.connect(_on_area_entered)
	collider.area_exited.connect(_on_area_exited)


func get_position(
	p_reference_position: Vector3,
	p_status := PositionGettingStatus.new()
) -> Vector3:
	update_reference_position(p_reference_position)
	if position_getting_status.got_position:
		p_status.got_position = true
	return position


func update_reference_position(
	p_position: Vector3,
) -> void:
	reference_position = p_position
	_update_position()


# Override.
func _update_position() -> void:
	if is_colliding():
		position = colliding_objects.get_first().transform.origin
	else:
		position = collider.transform.origin
	# This implementation's always got a relevant position.
	# In your subclass, you'll want to set that to `false` in cases where
	# no relevant position has been found.
	position_getting_status.got_position = true


func _add_colliding_object(p_colliding_object: CollisionObject3D) -> void:
	colliding_objects.add(p_colliding_object)
	_update_position()


func _remove_colliding_object(p_colliding_object: CollisionObject3D) -> void:
	colliding_objects.remove(p_colliding_object)
	_update_position()


#==========================================================================
# Signal receiver methods
#==========================================================================


func _on_reference_position_change(p_position: Vector3) -> void:
	update_reference_position(p_position)


func _on_area_entered(p_area: Area3D) -> void:
	_add_colliding_object(p_area)


func _on_area_exited(p_area: Area3D) -> void:
	_remove_colliding_object(p_area)


func _on_body_entered(p_body: PhysicsBody3D) -> void:
	_add_colliding_object(p_body)


func on_body_exited(p_body: PhysicsBody3D) -> void:
	_remove_colliding_object(p_body)
