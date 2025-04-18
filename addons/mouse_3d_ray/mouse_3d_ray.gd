## A 3D mouse raycasting node that makes available all collisions for the the
## current frame in its `.collisions` property.
extends Node
class_name Mouse3DRay

@export var viewport: Viewport
@export var camera: Camera3D
@export var ray_caster := Mouse3DRayRayCaster.new()
@export var collide_with_areas := false
@export var collide_with_bodies := true
@export_flags_3d_physics var collision_mask := 4294967295
@export var exclude: Array[RID] = []
@export var hit_back_faces := true
@export var hit_from_inside := false
## Used to prevent infinite looping. Increase if you expect more collisions per
## mouse ray.
@export var max_tries := 1000
@export var fail_on_viewport_or_camera_missing := false
@export var show_integration_warnings := true
@export var show_missing_camera_warning := true
@export var show_missing_viewport_warning := true

var viewport_mouse_position_getter: CachingViewportMousePositionGetter
var collisions := Collisions.new()
# TODO: Add "Processor" stack, where it's possible to add nodes that will get
# called to do whatever it is they do. They would have a method that takes 
# a `Collisions` object.

## A wrapper for an array of result-dictionaries from `PhysicsDirectSpaceState3D.intersect_ray(...)`.
## The `.all` property holds the array.
## 
## The documentation for the `PhysicsDirectSpaceState3D.intersect_ray` method
## says (Godot 4.2):
##   The returned object is a dictionary with the following fields:
##     - collider: The colliding object.
##     - collider_id: The colliding object's ID.
##     - normal: The object's surface normal at the intersection point,
##       or Vector3(0, 0, 0) if the ray starts inside the shape and
##       PhysicsRayQueryParameters3D.hit_from_inside is true.
##     - position: The intersection point.
##     - face_index: The face index at the intersection point.
##       - Note: Returns a valid number only if the intersected shape is a
##         ConcavePolygonShape3D. Otherwise, -1 is returned.
##     - rid: The intersecting object's RID.
##     - shape: The shape index of the colliding shape.
##   If the ray did not intersect anything, then an empty dictionary is returned
##   instead.
class Collisions:
	const _CLASS_NAME := "Collisions"
	
	class Keys:
		const COLLIDER = "collider"
		const COLLIDER_ID = "collider_id"
		const NORMAL = "normal"
		const POSITION = "position"
		const FACE_INDEX = "face_index"
		const COLLIDER_RID = "rid"
		const SHAPE = "shape"
		
	## Result dictionaries as per `PhysicsDirectSpaceState3D.intersect_ray(...)`.
	## Is sorted by collision encounter along the ray (index 0 has the closest).
	## No-set: Assigning a (new) array will error.
	var all: Array[Dictionary] = []:
		set(p_value):
			push_error("Tried setting no-set property `%s.all`." % _CLASS_NAME)
	
	
	## Returns a dictionary where the keys are the colliders and the values
	## their corresponding collisions.
	func get_by_collider() -> Dictionary:
		var by_collider := {}
		for collision in all:
			by_collider[collision[Keys.COLLIDER]] = collision
		return by_collider
	
	
	## Returns a dictionary where the keys are the collider IDs and the values
	## their corresponding collisions.
	func get_by_id() -> Dictionary:
		var by_id := {}
		for collision in all:
			by_id[collision[Keys.COLLIDER_ID]] = collision
		return by_id
	
	
	## Are there any collisions?
	func exist() -> bool:
		return true if len(all) > 0 else false
	
	
	## Are there any collisions with this object?
	func with_object_exist(p_collider: CollisionObject3D) -> bool:
		for collision in all:
			if collision[Keys.COLLIDER] == p_collider:
				return true
		return false
	
	
	## Are there any collisions with an object with this ID?
	func with_object_by_id_exist(p_id: int) -> bool:
		for collision in all:
			if collision[Keys.COLLIDER_ID] == p_id:
				return true
		return false


func new_query_parameters() -> PhysicsRayQueryParameters3D:
	var viewport_mouse_position := viewport_mouse_position_getter.position
	
	var ray_normal := camera.project_ray_normal(viewport_mouse_position)
	var ray_length := camera.far
	var ray := ray_normal * ray_length
	
	var ray_origin := camera.project_ray_origin(viewport_mouse_position)
	var ray_end := ray_origin + ray
	
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		collision_mask,
		exclude,
	)
	query.collide_with_areas = collide_with_areas
	query.collide_with_bodies = collide_with_bodies
	query.hit_back_faces = hit_back_faces
	query.hit_from_inside = hit_from_inside
	
	return query


func get_space_state() -> PhysicsDirectSpaceState3D:
	return viewport.find_world_3d().direct_space_state


## Checks whether we have a viewport and/or camera set.
## Warns/errors and initializes if one or both are missing as configured.
## If `fail_on_viewport_or_camera_missing` is set, no initialization will
## happen.
## Returns `true` if a viewport and camera could be ensured, false otherwise.
## If this returns `false`, using this node will crash.
func ensure_sanity() -> bool:
	if viewport and not camera:
		if fail_on_viewport_or_camera_missing:
			var error_message := "No camera specified for %s." % get_name()
			push_error(error_message)
			assert(camera, error_message)
			return false
			
		camera = viewport.get_camera_3d()
		if show_integration_warnings and show_missing_camera_warning:
			push_warning(
				"No camera specified for %s. Using `get_camera_3d` from viewort." % get_name()
			)
			
	if camera and not viewport:
		if fail_on_viewport_or_camera_missing:
			var error_message := "No viewport specified for %s." % get_name()
			push_error(error_message)
			assert(viewport, error_message)
			return false
			
		viewport = camera.get_viewport()
		if show_integration_warnings and show_missing_viewport_warning:
			push_warning(
				"No viewport specified %s. Using `get_viewport()` from camera." % get_name()
			)
			
	if not viewport and not camera:
		if fail_on_viewport_or_camera_missing:
			var error_message := "Neither viewport nor camera are specified for %s." % get_name()
			push_error(error_message)
			assert((viewport and camera), error_message)
			return false
		
		viewport = get_viewport()
		camera = viewport.get_camera_3d()
		if show_integration_warnings\
		and (show_missing_viewport_warning or show_missing_camera_warning):
			push_warning(
				"Neither viewport nor camera specified for %s. Using viewport from " % get_name() +
				"`get_viewport()` and the camera from that viewport's `get_camera_3d()`."
			)
	
	return true


func ensure_caching_viewport_mouse_position_getter_attached() -> void:
	for child in viewport.get_children():
		if child is CachingViewportMousePositionGetter:
			viewport_mouse_position_getter = child
			return
	viewport_mouse_position_getter = CachingViewportMousePositionGetter.new(viewport)
	viewport.add_child(viewport_mouse_position_getter)


func _ready() -> void:
	ensure_sanity()
	ensure_caching_viewport_mouse_position_getter_attached()
