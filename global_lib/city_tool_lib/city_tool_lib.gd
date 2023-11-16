extends RefCounted
class_name CityToolLib

### "Imports": ToolLib
const ToolState := ToolLib.ToolState
const StateDuplicatingUndoableTool := ToolLib.StateDuplicatingUndoableTool


class StreetToolState extends ToolState:
	var curve := Curve3D.new()


class StreetTool extends StateDuplicatingUndoableTool:
	func _init():
		self._state = StreetToolState.new()
	
	func get_state() -> StreetToolState:
		return get_base_type_state() as StreetToolState
		
	func set_state(state: StreetToolState) -> void:
		set_base_type_state(state)
