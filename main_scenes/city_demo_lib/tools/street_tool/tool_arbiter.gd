extends Node

signal request_granted(granted: bool)
signal deactivate()
@onready var tool_default := Node.new()

enum State {
	NOTHING,
	ACTIVATION_REQUEST,
	TOOL_ACTIVE
}
var state := State.NOTHING
var activation_requesting_tool: Node:
	get:
		if not activation_requesting_tool:
			push_error(
				"Error: var `activation_requesting_tool` accessed before "
				+ "assignment. Will return `Node.new()`."
			)
			# This might cause errors related to tool activation to be slightly harder to
			# debug, but the question is: Do we want the game to crash because of tool
			# activation related errors? I'm gravitating towards "no".
			activation_requesting_tool = tool_default
		if not state == State.ACTIVATION_REQUEST:
			push_error("Error: var `activation_requesting_tool` accessed "
			+ "outside of `ACTIVATION_REQUEST` state.")
		return activation_requesting_tool
	set(value):
		activation_requesting_tool = value
var active_tool: Node:
	get:
		if not active_tool:
			push_error(
				"Error: var `active_tool` before "
				+ "assignment. Will return `Node.new()`."
			)
			# This might cause errors related to tool activation to be slightly harder to
			# debug, but the question is: Do we want the game to crash because of tool
			# activation related errors? I'm gravitating towards "no".
			active_tool = tool_default
		return active_tool
	set(value):
		active_tool = value

func reset():
	state = State.NOTHING
	active_tool = tool_default
	activation_requesting_tool = tool_default

func set_activation_request_state(tool: Node):
	state = State.ACTIVATION_REQUEST
	activation_requesting_tool = tool
 
func _on_request_activation(tool: Node):
	if state == State.NOTHING:
		print("NOTHING")
		set_activation_request_state(tool)
		request_granted.emit(true)
		return
		
	if state == State.TOOL_ACTIVE:
		print("TOOL_ACTIVE")
		set_activation_request_state(tool)
		deactivate.connect(active_tool._on_deactivate, CONNECT_ONE_SHOT)
		deactivate.emit()
		return
		
	print("fallthrough")
	request_granted.emit(false)
	
func _on_tool_deactivated():
	print("_on_tool_deactivated")
	if state == State.ACTIVATION_REQUEST:
		print("request granted, not first run")
		request_granted.emit(true)
		return
	print("reset")
	reset()
	
func _on_tool_activated():
	print("_on_tool_activated called")
	active_tool = activation_requesting_tool
	state = State.TOOL_ACTIVE
	
