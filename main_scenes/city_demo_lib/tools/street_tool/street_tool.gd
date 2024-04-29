extends CityToolLib.StreetTool

## Used to get the actual corresponding map points to our curve points.
signal request_map_points(source_points: PackedVector3Array)
## Fired on in-edit changes to the street of interest to previewers.
## Code listening for this should be fast enough to potentially run every frame.
signal street_previewably_changed(
	p_points: PackedVector3Array,
	p_point_transforms: Array[Transform3D],
	p_profile2d: PackedVector2Array,
)

enum StreetToolMapRayCasterRequestTypeId {
	CURVE,
	LEFT_SIDE,
	RIGHT_SIDE
}
## Set to true when the final request for building the street is made, so
## signal responders involved in that process know that the tool is finishing
## up.
var build_requested = false

@export var map_agent: ToolLibMapAgent
@export var map_ray_caster: ToolMapRayCaster
## A polygon used to extrude as a mesh along the map-adjused street curve
## points.
var _bounding_box_profile2d := PackedVector2Array([
	Vector2(0.5, 0.1),
	Vector2(0.5, -0.1),
	Vector2(-0.5, -0.1),
	Vector2(-0.5, 0.1)
])


func _check_vars_exist(
	p_err_msgs: PackedStringArray,
	p_vars: Dictionary
) -> PackedStringArray:
	for var_name in p_vars:
		if not p_vars[var_name]:
			var err_msg: String = "`%s` not set" % var_name
			p_err_msgs.append(err_msg)
			push_error(err_msg)
	return p_err_msgs


func _on_ready_sanity_checks(
	# Not having a default forces the site of call to specify an array, making
	# things more explicit and making it less likely that, by forgetting to
	# specify an array, a new array is returned by accident (in scenarios where
	# the array is passed to more than one sanity-check-style function), whichcould lead to confusing bugs in error reporting.
	p_err_msgs: PackedStringArray,
	p_with_asserts := true
) -> PackedStringArray:
	var initial_err_msg_count := len(p_err_msgs)
	_check_vars_exist(
		p_err_msgs,
		{}
	)
	
	var errors_found := len(p_err_msgs) - initial_err_msg_count > 0
	assert(
		!(p_with_asserts and errors_found),
		"Errors for `%s`: %s" % [get_name(), String(", ").join(p_err_msgs)]
	)
	return p_err_msgs


func activate() -> void:
	super()
	map_agent.mouse_button.connect(_on_map_mouse_button)
	map_agent.mouse_position_change.connect(_on_map_mouse_position_change)


func deactivate() -> void:
	super()
	map_agent.mouse_button.disconnect(_on_map_mouse_button)
	map_agent.mouse_position_change.disconnect(_on_map_mouse_position_change)


func _ready() -> void:
	if len(_on_ready_sanity_checks(PackedStringArray())) > 0:
		push_error(
			"Failed to initialize `%s`. " % get_name()
			+ "See earlier error(s)."
		)


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
				map_agent.get_map_node(),
				Transform3D(Basis(), get_state().curve.get_point_position(idx))
			)
		else:
			#get_state().node_metadata[get_last_node_idx()].out_point_finalized = true
			#get_state().node_finalizations[get_last_node_idx()].handle_out = FINALIZED
			set_node_handle_out_point(
				get_last_node_idx(),
				p_mouse_position - get_state().curve.get_point_position(get_last_node_idx()),
				FINALIZED
			)


func _on_map_mouse_position_change(
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
	if get_node_count() > 1:
		print("street_tool.gd: on map mouse position change")
		_update_street()


func _get_point_transforms(p_map_points: PackedVector3Array) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	
	for i_map_point in range(len(p_map_points)):
		transforms.append(
			Transform3D(
				GeoFoo.get_baked_point_transform(get_state().curve, i_map_point).basis,
				p_map_points[i_map_point]
			)
		)
	
	return transforms


func _emit_street_previewably_changed(p_map_points: PackedVector3Array) -> void:
	print("street_tool.gd: Emitting previewably changed")
	street_previewably_changed.emit(
		p_map_points,
		_get_point_transforms(p_map_points),
		_bounding_box_profile2d
	)


## This fires when the final street build is kicked off by the user, e.g.
## by clicking a button that sends a signal here.
func _on_request_build_street() -> void:
	build_requested = true
	_update_street()


## Run every time the street has previewable changes.
func _update_street() -> void:
	request_map_points.emit(
		ToolMapRayCaster.Request.new(
			StreetToolMapRayCasterRequestTypeId.CURVE,
			get_state().curve.get_baked_points()
		)
	)
	# Now it's up to `StreetToolMapRayCaster` to answer back. Once it does,
	# `_on_result_map_points` below will be kicked off.


func _on_result_map_points(p_result: ToolMapRayCaster.Result) -> void:
	if build_requested:
		_build_street(p_result.map_points)
	else:
		print("street_tool.gd: not build requested")
		if get_node_count() > 1:
			_emit_street_previewably_changed(p_result.map_points)


func _build_street(p_map_points: PackedVector3Array) -> void:
	_add_street_to_map(
		_create_street(
			p_map_points
		)
	)


func _create_street(p_map_points: PackedVector3Array) -> MeshInstance3D:
	return StreetMesh.create_network_segment(
		p_map_points,
		_get_point_transforms(p_map_points),
		_bounding_box_profile2d 
	)


func _add_street_to_map(p_street_mesh: MeshInstance3D) -> void:
	map_agent.get_map_node().add_child(p_street_mesh)

