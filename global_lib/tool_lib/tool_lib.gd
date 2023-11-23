extends RefCounted
class_name ToolLib


class ToolState extends Resource:
	pass


class StatefulTool extends Node:
	#func get_class() -> String: return "StatefulTool"
	signal state_updated()
	
	# Override in sub-class is mandatory.
	#
	# Sub-classes and their calling contexts will have to use `as ...` in order
	# to type-cast the return value to the appropriate `ToolState` sub-class.
	# One convention could be for sub-classes to have their own `get_state`
	# method, which returns, for example, `self._state as WhateverToolState`.
	# (To make room for that convention, this method isn't named `get_state`.)
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
		self._redo_buffer.clear()
		
	func get_base_type_state() -> ToolState:
		return self._state
	
	func set_base_type_state(state: ToolState) -> void:
		prepare_buffers()
		self._state = state
	
	func copy_state_to_undo():
		self._undo_buffer.append(copy_base_type_state())
		
	func undo() -> void:
		if len(self._undo_buffer) == 0:
			return
		
		var previous_state: ToolState = self._undo_buffer.pop_back()
		self._redo_buffer.append(_state)
		self._state = previous_state
		self.state_reset.emit()
		
	func redo() -> void:
		if len(self._redo_buffer) == 0:
			return
			
		var most_recent_undone_state: ToolState = self._redo_buffer.pop_back()
		self._undo_buffer.append(self._state)
		self._state = most_recent_undone_state
		self.state_reset.emit()
