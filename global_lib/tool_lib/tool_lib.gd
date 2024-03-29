extends RefCounted
class_name ToolLib


class ToolState extends Resource:
	pass


class Tool extends Node:
	signal activated()
	signal deactivated()
	
	func activate() -> void:
		activated.emit()
	
	func deactivate() -> void:
		deactivated.emit()
	
	# @virtual
	func _on_activation_requested(_p_activator_agent: ToolLibToolActivatorAgent):
		pass
	
	# @virtual
	func _on_deactivation_requested(_p_activator_agent: ToolLibToolActivatorAgent):
		pass


class StatefulTool extends Tool:
	#func get_class() -> String: return "StatefulTool"
	signal state_updated()
	
	# Override in sub-class is mandatory.
	#
	# Sub-classes and their calling contexts will have to use `as ...` in order
	# to type-cast the return value to the appropriate `ToolState` sub-class.
	# One convention could be for sub-classes to have their own `get_state`
	# method, which returns, for example, `self._state as WhateverToolState`.
	# (To make room for that convfention, this method isn't named `get_state`.)
	# 
	# This method exists for situations where that's not practical. Of course,
	# the type-cast would then have to be done at the site of call.
	func get_base_type_state() -> ToolState:
		var err_msg := "Unimplemented virtual method `get_base_type_state` of "\
			+ "`%s` called." % self.get_class()
		push_error(err_msg)
		assert(false, err_msg)
		return ToolState.new()
		
	func copy_base_type_state() -> ToolState:
		return get_base_type_state().duplicate(true)


# Base class for tools with undo capability.
class UndoableTool extends StatefulTool:
	# Override in sub-class.
	func undo() -> void:
		pass
		
	# Override in sub-class.
	func redo() -> void:
		pass


class StateDuplicatingUndoableTool extends UndoableTool:
	var _state: ToolState
	var _undo_buffer: Array[ToolState]
	var _redo_buffer: Array[ToolState]
	signal state_reset()
	
	func prepare_buffers():
		copy_state_to_undo()
		_redo_buffer.clear()
		
	func get_base_type_state() -> ToolState:
		return _state
	
	func set_base_type_state(p_state: ToolState) -> void:
		prepare_buffers()
		_state = p_state
	
	func copy_state_to_undo():
		_undo_buffer.append(copy_base_type_state())
		
	func undo() -> void:
		if len(_undo_buffer) == 0:
			return
		
		var previous_state: ToolState = _undo_buffer.pop_back()
		_redo_buffer.append(_state)
		_state = previous_state
		state_reset.emit()
		
	func redo() -> void:
		if len(_redo_buffer) == 0:
			return
			
		var most_recent_undone_state: ToolState = _redo_buffer.pop_back()
		_undo_buffer.append(_state)
		_state = most_recent_undone_state
		state_reset.emit()
