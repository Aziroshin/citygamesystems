extends CityToolLib.CurveLayoutTool

@export var map: PlaneMap


func activate() -> void:
	super()
	map.mouse_button.connect(_on_map_mouse_button)
	map.mouse_motion.connect(_on_map_mouse_motion)


func deactivate() -> void:
	super()
	map.mouse_button.disconnect(_on_map_mouse_button)
	map.mouse_motion.disconnect(_on_map_mouse_motion)


func _on_map_mouse_button(
	_p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	# TODO: This will need to be properly tied into actions, but also in
	# a way modular enough that it won't be a pain to integrate the tool into
	# other codebases.
	if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.pressed:
		if get_node_count() == 0:
			cursor.current_idx = add_node(p_mouse_position, UNFINALIZED)
		if get_node_count() >= 2:
			cursor.current_idx = add_node(p_mouse_position, UNFINALIZED)
		Cavedig.needle(
			map,
			Transform3D(Basis(), get_state().curve.get_point_position(cursor.current_idx))
		)


func _on_map_mouse_position_change(
	_p_camera: Camera3D,
	_p_event: InputEvent,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	if get_node_count() == 1 and not p_mouse_position == cursor.current_position_ro:
		cursor.current_idx = add_node(p_mouse_position, FINALIZED)
	if get_node_count() >= 2:
		if p_mouse_position == cursor.previous_position_ro:
			return
		set_node_position(cursor.current_idx, p_mouse_position, false)
		
		var current_node_in_point := cursor.previous_position_ro - cursor.current_position_ro
		var current_node_out_point := -(cursor.previous_position_ro - cursor.current_position_ro)
		var previous_node_out_point := cursor.current_position_ro - cursor.previous_position_ro
		
		set_node_handle_in_point(
			cursor.current_idx,
			current_node_in_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.current_idx,
			current_node_out_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.previous_idx_ro,
			previous_node_out_point,
			UNFINALIZED
		)
