extends CityToolLib.StreetTool

signal request_activation(p_tool: Node)
## Used to get the actual corresponding map points to our curve points.
signal request_map_points(source_points: PackedVector3Array)

enum ActivationState {
	INACTIVE,
	WAITING_FOR_ACTIVATION,
	ACTIVE,
	DEACTIVATING
}
enum StreetToolMapRayCasterRequestTypeId {
	CURVE,
	LEFT_SIDE,
	RIGHT_SIDE
}
@export var arbiter: Node
# That typing is quite opinionated, of course, and is bound to change as things
# develop. A better approach would be to have a `street_node_agent` Node
# between the tool and the map which deals with the map-specific things, but
# for prototyping, and for the purposes of the demo, I feel it'd add quite a bit
# of overhead to development and slow down experimentation.
@export var map: PlaneMap
@export var map_ray_caster: StreetToolMapRayCaster
var activation_state := ActivationState.INACTIVE


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
		{"arbiter": arbiter, "map": map}
	)
	
	# In anticipation of changes to the map setup and type, let's be sure.
	if "map" in self:
		if not map.has_signal("mouse_button"):
			p_err_msgs.append(
				"`map` doesn't have a `mouse_button` signal. "
				+ "`%s` won't work." % get_name()
			)
			
	var errors_found := len(p_err_msgs) - initial_err_msg_count > 0
	assert(
		!(p_with_asserts and errors_found),
		"Errors for `%s`: %s" % [get_name(), String(", ").join(p_err_msgs)]
	)
	return p_err_msgs


func _activate() -> void:
	map.mouse_button.connect(_on_map_mouse_button)
	map.mouse_motion.connect(_on_map_mouse_motion)


func _deactivate() -> void:
	map.mouse_button.disconnect(_on_map_mouse_button)
	map.mouse_motion.disconnect(_on_map_mouse_motion)


func _ready() -> void:
	if len(_on_ready_sanity_checks(PackedStringArray())) > 0:
		push_error(
			"Failed to initialize `%s`. " % get_name()
			+ "See earlier error(s)."
		)


## Button signals and stuff should hook up to this. Hotkeys would probably
## have to be captured by some node, which then signals here.
func _on_activation_requested(_p_activator_agent: ToolLibToolActivatorAgent) -> void:
	if activation_state == ActivationState.INACTIVE:
		arbiter.request_granted.connect(
			_on_request_granted,
			CONNECT_ONE_SHOT
		)
		request_activation.connect(
			arbiter._on_request_activation,
			CONNECT_ONE_SHOT
		)
		request_activation.emit(self)


func _start_deactivating() -> void:
	if activation_state == ActivationState.ACTIVE:
		activation_state = ActivationState.DEACTIVATING
		_on_deactivate()


func _on_deactivation_requested(_p_activator_agent: ToolLibToolActivatorAgent) -> void:
	_start_deactivating()


func _on_request_granted(p_granted: bool) -> void:
	if p_granted:
		activation_state = ActivationState.ACTIVE
		_activate()
		activated.connect(arbiter._on_tool_activated, CONNECT_ONE_SHOT)
		activated.emit()


func _on_deactivate() -> void:
	_deactivate()
	activation_state = ActivationState.INACTIVE
	deactivated.connect(arbiter._on_tool_deactivated, CONNECT_ONE_SHOT)
	deactivated.emit()


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
			#get_state().node_metadata[get_last_node_idx()].out_point_finalized = true
			#get_state().node_finalizations[get_last_node_idx()].handle_out = FINALIZED
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


func _on_request_build_street() -> void:
	request_map_points.emit(
		StreetToolMapRayCaster.Request.new(
			StreetToolMapRayCasterRequestTypeId.CURVE,
			get_state().curve.get_baked_points()
		)
	)
	# Now it's up to `StreetToolMapRayCaster` to answer back. Once it does,
	# `_on_result_map_points` below will be kicked off.

func _on_result_map_points(p_result: StreetToolMapRayCaster.Result) -> void:
	#for point in p_result.map_points:
		#Cavedig.needle(
			#map,
			#Transform3D(Basis(), point),
			#Vector3(0.85, 0.1, 0.75),
			#0.3,
			#0.02
		#)
	_build_street(p_result.map_points)


func _build_street(p_map_points: PackedVector3Array) -> void:
	
	#----- Build Street
	_add_street_to_map(
		_create_street(
			p_map_points
		)
	)


func _create_street(p_map_points: PackedVector3Array) -> MeshInstance3D:
	var profile2d := PackedVector2Array([
		Vector2(0.5, 0.1),
		Vector2(0.5, -0.1),
		Vector2(-0.5, -0.1),
		Vector2(-0.5, 0.1)
	])
	var transforms: Array[Transform3D] = []
	
	for i_map_point in range(len(p_map_points)):
		transforms.append(
			Transform3D(
				GeoFoo.get_baked_point_transform(get_state().curve, i_map_point).basis,
				p_map_points[i_map_point]
			)
		)
	
	return StreetMesh.create_network_segment(
		p_map_points,
		transforms,
		profile2d
	)


func _add_street_to_map(p_street_mesh: MeshInstance3D) -> void:
	map.add_child(p_street_mesh)

