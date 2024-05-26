extends CityToolLib.StreetTool

## "Imports": CityToolLib
const CurveCursor := CityToolLib.CurveCursor
const StreetToolState := CityToolLib.StreetToolState

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
var build_requested := false
## `true` when waiting for a response from the `.map_ray_caster`, so the data
## sent from the raycaster doesn't get matched up with curve data that changed
## in the interim.
var waiting_for_map_points := false
## Used to store the first mouse click when waiting for map points. Questionable
## workaround for clicks getting lost as the tool is in waiting mode.
var click_buffer := SingleFirstSignalBuffer.new()

@export var life_cyclers: CityGameWorldObjectLifeCyclers
@export var map_agent: ToolLibMapAgent
@export var map_ray_caster: ToolMapRayCaster
@onready var cursor := CurveCursor.new(get_state().curve)
var outer_radius := 0.5
var inner_radius_ratio := 0.8
var inner_radius = outer_radius * inner_radius_ratio
## A polygon used to extrude as a mesh along the map-adjused street curve
## points.
var _bounding_box_profile2d := PackedVector2Array([
	Vector2(outer_radius, 0.1),
	Vector2(outer_radius, -0.1),
	Vector2(-outer_radius, -0.1),
	Vector2(-outer_radius, 0.1)
])
var _debug_node_adding_visualizer: CSGCylinder3D


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
		{
			"map_agent": "@export var map_agent not defined.",
			"map_ray_caster": "@export var map_ray_caster not defined."
		}
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


func is_in_handle_setting_mode() -> bool:
	return !is_in_node_adding_mode()


## Calls `set_node_handle_out_point` with `FINALIZED`.
func set_node_handle_out_point_and_enter_node_adding_mode(
		p_idx: int,
		p_position: Vector3,
	) -> void:
		set_node_handle_out_point(
			p_idx,
			p_position,
			FINALIZED
		)


func add_node(
	p_position: Vector3,
	p_finalized: bool,
) -> int:
	cursor.current_idx = super(p_position, p_finalized)
	return cursor.current_idx


func enter_handle_setting_mode():
	get_state().node_finalizations[cursor.current_idx].point = FINALIZED


## Calls `add_node` with `FINALIZED`.
func add_node_and_enter_handle_setting_mode(p_position: Vector3,) -> int:
	return add_node(p_position, FINALIZED)


func _ready() -> void:
	if len(_on_ready_sanity_checks(PackedStringArray(), true)) > 0:
		push_error(
			"Failed to initialize `%s`. " % get_name()
			+ "See earlier error(s)."
		)


func _set_debug_node_adding_visualizer(p_position: Vector3) -> void:
	if not _debug_node_adding_visualizer:
		_debug_node_adding_visualizer = Cavedig.needle(
			map_agent.get_map_node(),
			Transform3D(Basis(), p_position),
			Vector3(0.1, 0.8, 0.3),
			0.8,
			0.14
		)
		return
	_debug_node_adding_visualizer.transform.origin = p_position


func _on_map_mouse_button(
	p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_mouse_position: Vector3,
	p_normal: Vector3,
	p_shape: int
) -> void:
	if waiting_for_map_points:
		click_buffer.push(
			InputEventMouseSignalBufferCall.new(
				p_camera, p_event, p_mouse_position, p_normal, p_shape
			),
			_on_map_mouse_button
		)
		return
	
	# TODO: This will need to be properly tied into actions, but also in
	# a way modular enough that it won't be a pain to integrate the tool into
	# other codebases.
	if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.pressed:
		if not get_state().node_finalizations[cursor.current_idx].point:
			set_node_position(
				cursor.current_idx,
				p_mouse_position,
				FINALIZED
			)
			Cavedig.needle(
				map_agent.get_map_node(),
				Transform3D(Basis(), cursor.current_position_ro)
			)
		elif not get_state().node_finalizations[cursor.current_idx].handle_out:
			set_node_handle_out_point(
				cursor.current_idx,
				p_mouse_position - cursor.current_position_ro,
				FINALIZED
			)
			# New (current) point
			add_node(
				p_mouse_position,
				UNFINALIZED
			)


func _on_map_mouse_position_change(
	_p_camera: Camera3D,
	_p_event: InputEvent,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	if waiting_for_map_points:
		return
	
	if get_node_count() == 0:
		add_node(
			p_mouse_position,
			UNFINALIZED
		)
	if not get_state().node_finalizations[cursor.current_idx].point:
		set_node_position(
			cursor.current_idx,
			p_mouse_position,
			UNFINALIZED
		)
		if get_node_count() > 1:
			set_node_handle_in_point(
				cursor.current_idx,
				GeoFoo.get_point_to_preceding_point_out(
					get_state().curve,
					cursor.current_idx,
					true,
					0.1
				),
				UNFINALIZED,
			)
	elif not get_state().node_finalizations[cursor.current_idx].handle_out:
		if not get_state().curve.get_point_position(cursor.current_idx) == p_mouse_position:
			set_node_handle_out_point(
				cursor.current_idx,
				p_mouse_position - cursor.current_position_ro,
				UNFINALIZED
			)
	if get_node_count() > 1:
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
	waiting_for_map_points = true
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
		_do_and_finish(p_result.map_points)
	else:
		_emit_street_previewably_changed(p_result.map_points)
	waiting_for_map_points = false
	click_buffer.flush()


func _build_street(p_map_points: PackedVector3Array) -> void:
	var street_mesh := _create_street(p_map_points)
	var street_segment := life_cyclers.street_segment.create(
		get_state().curve.duplicate(true),
		outer_radius,
		p_map_points
	)
	#street_segment.add_child(street_mesh)
	_add_street_to_map(street_segment)


func _create_street(p_map_points: PackedVector3Array) -> MeshInstance3D:
	return StreetMesh.create_network_segment(
		p_map_points,
		_get_point_transforms(p_map_points),
		_bounding_box_profile2d 
	)


func _add_street_to_map(p_street_segment: StreetSegmentWorldObject) -> void:
	map_agent.get_map_node().add_child(p_street_segment)


#==========================================================================
# BEGIN: Reset functions
# They get called when the tool is getting reset to a blank
# state.
# The existence of these things here is a prototyping fragment, as
# ideally, they would be a part of the tool state.
#==========================================================================


## Initializes a blank state.
## Not the same as the `reset` signal on the state.
func _reset_state() -> void:
	set_state(StreetToolState.new())
	emit_curve_changed()


func _reset() -> void:
	_reset_state()
	_emit_street_previewably_changed(PackedVector3Array())
	cursor = CurveCursor.new(get_state().curve)
	build_requested = false

# END: Reset functions
#==========================================================================


func _finish() -> void:
	deactivate()


func _do_and_finish(p_map_points: PackedVector3Array) -> void:
	_build_street(p_map_points)
	_reset()
	_finish()
