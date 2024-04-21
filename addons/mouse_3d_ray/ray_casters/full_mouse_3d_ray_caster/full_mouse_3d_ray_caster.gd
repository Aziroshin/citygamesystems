## A raycasting component for a `Mouse3DRay` that picks all the objects it
## If the corresponding `Mouse3DRay` is not set directly, `_ready()` will
## check if the owner node is a `Mouse3DRay` and set it to that if it is.
## If no `Mouse3DRay` can be established, an error is pushed.
extends Mouse3DRayRayCaster
class_name Mouse3DRayFullRayCaster


func ensure_sanity() -> void:
	if not mouse_3d_ray:
		if get_parent() is Mouse3DRay:
			mouse_3d_ray = get_parent()
		else:
			var err_msg := "No `Mouse3DRay` for this raycaster node "\
				+ "(name: `%s`, owner name: %s)." % [name, owner.name]
			push_error(err_msg)
			assert(false, err_msg)


func _ready():
	ensure_sanity()


# Reference on the topic of getting the mouse position (Godot 4.1):
#   https://stackoverflow.com/questions/76893256/how-to-get-the-3d-mouse-pos-in-godot-4-1
#   See answer by Theraot (https://stackoverflow.com/users/402022/theraot)
func _physics_process(_p_delta: float) -> void:
	mouse_3d_ray.collisions.all.clear()
	
	var space_state := mouse_3d_ray.get_space_state()
	var query := mouse_3d_ray.new_query_parameters()
	
	var try_count := 0
	while try_count < mouse_3d_ray.max_tries:
		try_count += 1
		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			mouse_3d_ray.collisions.all.append(result)
			# Appending to `query.exclude` directly doesn't work for some
			# reason, so we do that (for now?).
			var exclude: Array[RID] = query.exclude
			exclude.append(result[mouse_3d_ray.collisions.Keys.COLLIDER_RID])
			query.exclude = exclude
		else:
			break
