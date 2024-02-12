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
		if is_in_node_adding_mode():
			var idx := add_node(p_mouse_position, true)
			Cavedig.needle(
				map,
				Transform3D(Basis(), get_state().curve.get_point_position(idx))
			)
		else:
			set_node_handle_out_point(
				get_last_node_idx(),
				p_mouse_position - get_state().curve.get_point_position(get_last_node_idx()),
				FINALIZED
			)


func _on_map_mouse_motion(
	_p_camera: Camera3D,
	_p_event: InputEvent,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	if\
	get_node_count() > 0\
	and not get_state().node_finalizations[get_last_node_idx()].handle_out:
		set_node_handle_out_point(
			get_last_node_idx(),
			p_mouse_position - get_state().curve.get_point_position(get_last_node_idx()),
			UNFINALIZED
		)
