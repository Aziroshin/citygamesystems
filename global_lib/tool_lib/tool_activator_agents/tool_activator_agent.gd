extends Node
class_name ToolLibToolActivatorAgent

# "Imports": ToolLib
const Tool := ToolLib.Tool

signal request_tool_activation(activator: ToolLibToolActivatorAgent)
signal request_tool_deactivation(activator: ToolLibToolActivatorAgent)

enum State {
	TOOL_ACTIVE,
	TOOL_INACTIVE
}
var state: State = State.TOOL_INACTIVE
# Only assign `ToolArbiterAgent` or sub-classes of it here.
# The inspector doesn't seem to accept sub-classes of `ToolArbiterAgent`
# (maybe godot bug?). To work around that it accepts any `Node` for now.
# Don't interact with this variable in any other way. Use `tool` instead.
@export var _arbiter_agent: Node
var arbiter_agent: ToolArbiterAgent:
	get:
		return _arbiter_agent as ToolArbiterAgent
	set(p_value):
		arbiter_agent = p_value


# @virtual
func _set_activator_to_active() -> void:
	pass


# @virtual
func _set_activator_to_inactive() -> void:
	pass


func _on_activator_toggling() -> void:
	if state == State.TOOL_ACTIVE:
		request_tool_deactivation.emit(self)
	elif state == State.TOOL_INACTIVE:
		request_tool_activation.emit(self)


func _on_tool_activated() -> void:
	print("tool_activator_agent.gd._on_tool_activated called.")
	state = State.TOOL_ACTIVE
	_set_activator_to_active()


func _on_tool_deactivated() -> void:
	state = State.TOOL_INACTIVE
	_set_activator_to_inactive()


func _ready():
	request_tool_activation.connect(arbiter_agent._on_activation_requested)
	request_tool_deactivation.connect(arbiter_agent._on_deactivation_requested)
	arbiter_agent.tool.activated.connect(_on_tool_activated)
	arbiter_agent.tool.deactivated.connect(_on_tool_deactivated)
