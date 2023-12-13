extends CityToolLib.StreetTool

signal request_activation(p_tool: Node)

enum ActivationState {
	INACTIVE,
	WAITING_FOR_ACTIVATION,
	ACTIVE,
	DEACTIVATING
}
@export var arbiter: Node
# That typing is quite opinionated, of course, and is bound to change as things
# develop. A better approach would be to have a `street_node_agent` Node
# between the tool and the map which deals with the map-specific things, but
# for prototyping, and for the purposes of the demo, I feel it'd add quite a bit
# of overhead to development and slow down experimentation.
@export var map: PlaneMap
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
	# specify an array, a new array is returned by accident, which could lead
	# to confusing bugs in error reporting.
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


func _deactivate() -> void:
	map.mouse_button.disconnect(_on_map_mouse_button)


func _ready() -> void:
	if len(_on_ready_sanity_checks(PackedStringArray())) > 0:
		push_error(
			"Failed to initialize `%s`. " % get_name()
			+ "See earlier error(s)."
		)


# Button signals and stuff should hook up to this. Hotkeys would probably
# have to be captured by some node, which then signals here.
func _on_activation_requested(_p_activator_agent: ToolLibToolActivatorAgent):
	if activation_state == ActivationState.INACTIVE:
		print("tool: activation requested. ActivationState: %s" % activation_state)
		arbiter.request_granted.connect(
			_on_request_granted,
			CONNECT_ONE_SHOT
		)
		request_activation.connect(
			arbiter._on_request_activation,
			CONNECT_ONE_SHOT
		)
		request_activation.emit(self)


func _on_deactivation_requested(_p_activator_agent: ToolLibToolActivatorAgent):
	if activation_state == ActivationState.ACTIVE:
		print("tool: deactivation requested. ActivationState: %s" % activation_state)
		activation_state = ActivationState.DEACTIVATING
		_on_deactivate()


func _on_request_granted(p_granted: bool):
	if p_granted:
		activation_state = ActivationState.ACTIVE
		_activate()
		activated.connect(arbiter._on_tool_activated, CONNECT_ONE_SHOT)
		activated.emit()


func _on_deactivate():
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
	if p_event.pressed:
		var idx := add_node(p_mouse_position)
		Cavedig.needle(
			map,
			Transform3D(Basis(), get_state().curve.get_point_position(idx))
		)
