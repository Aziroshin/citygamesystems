extends CityToolLib.StreetTool

signal request_activation(tool: Node)
signal activated()
signal deactivated()
@export var arbiter: Node
# That typing is quite opinionated, of course, and is bound to change as things
# develop. A better approach would be to have a `street_node_agent` Node
# between the tool and the map which deals with the map-specific things, but
# for prototyping, and for the purposes of the demo, I feel it'd add quite a bit
# of overhead to development and slow down experimentation.
@export var map: PlaneMap
var active: bool

func _check_vars_exist(
	err_msgs: PackedStringArray,
	vars: Dictionary
) -> PackedStringArray:
	for var_name in vars:
		if not vars[var_name]:
			var err_msg: String = "`%s` not set" % var_name
			err_msgs.append(err_msg)
			push_error(err_msg)
	return err_msgs
	
func _on_ready_sanity_checks(
	# Not having a default forces the site of call to specify an array, making
	# things more explicit and making it less likely that, by forgetting to
	# specify an array, a new array is returned by accident, which could lead
	# to confusing bugs in error reporting.
	err_msgs: PackedStringArray,
	with_asserts := true
) -> PackedStringArray:
	_check_vars_exist(
		err_msgs,
		{"arbiter": arbiter, "map": map}
	)
	
	if len(err_msgs) > 0:
		assert(
			!with_asserts,
			"Errors for `%s`: %s." % [get_name(), String(", ").join(err_msgs)]
		)
	return err_msgs

func _activate() -> void:
	pass
	
func _deactivate() -> void:
	pass

func _ready() -> void:
	if len(_on_ready_sanity_checks(PackedStringArray())) > 0:
		push_error(
			"Failed to initialize `%s`. " % get_name()
			+ "See earlier error(s)."
		)
	
# Button signals and stuff should hook up to this. Hotkeys would probably
# have to be captured by some node, which then signals here.
func _on_activation_requested():
	arbiter.request_granted.connect(_on_request_granted, CONNECT_ONE_SHOT)
	request_activation.connect(arbiter._on_request_activation, CONNECT_ONE_SHOT)
	request_activation.emit(self)

func _on_request_granted(granted: bool):
	if granted:
		self.active = true
		_activate()
		activated.connect(arbiter._on_tool_activated, CONNECT_ONE_SHOT)
		activated.emit()
		
	
func _on_deactivate():
	_deactivate()
	self.active = false
	deactivated.connect(arbiter._on_tool_deactivated, CONNECT_ONE_SHOT)
	deactivated.emit()
