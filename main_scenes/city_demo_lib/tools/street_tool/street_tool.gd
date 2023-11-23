extends CityToolLib.StreetTool

signal request_activation(tool: Node)
signal activated()
signal deactivated()
@export var arbiter: Node
var active: bool


func _ready() -> void:
	# Catch it here, so we won't have to check for the arbiter existing
	# all the time.
	if not arbiter:
		var err_msg := "arbiter for %s not set." % get_name()
		push_error(err_msg)
		assert(false, err_msg)
	
# Button signals and stuff should hook up to this. Hotkeys would probably
# have to be captured by some node, which then signals here.
func _on_activation_requested():
	arbiter.request_granted.connect(_on_request_granted, CONNECT_ONE_SHOT)
	request_activation.connect(arbiter._on_request_activation, CONNECT_ONE_SHOT)
	request_activation.emit(self)

func _on_request_granted(granted: bool):
	if granted:
		self.active = true
		activated.connect(arbiter._on_tool_activated, CONNECT_ONE_SHOT)
		activated.emit()
		
	
func _on_deactivate():
	self.active = false
	deactivated.connect(arbiter._on_tool_deactivated, CONNECT_ONE_SHOT)
	deactivated.emit()
