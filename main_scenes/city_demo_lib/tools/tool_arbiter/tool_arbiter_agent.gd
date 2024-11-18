extends Node
class_name ToolArbiterAgent

signal request_activation(p_tool: Node)
@export var arbiter: Node
@onready var tool := $".."
enum ActivationState {
	INACTIVE,
	WAITING_FOR_ACTIVATION,
	ACTIVE,
	DEACTIVATING
}
var activation_state := ActivationState.INACTIVE


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


func _activate_tool() -> void:
	tool.activated.connect(arbiter._on_tool_activated, CONNECT_ONE_SHOT)
	tool.activate()
	tool.deactivated.connect(arbiter._on_tool_deactivated, CONNECT_ONE_SHOT)
	tool.deactivated.connect(_on_tool_deactivated, CONNECT_ONE_SHOT)


func _deactivate_tool() -> void:
	tool.deactivate()


func _on_request_granted(p_granted: bool) -> void:
	if p_granted:
		activation_state = ActivationState.ACTIVE
		_activate_tool()


func _on_deactivate() -> void:
	_deactivate_tool()
	

func _on_tool_deactivated() -> void:
	activation_state = ActivationState.INACTIVE
