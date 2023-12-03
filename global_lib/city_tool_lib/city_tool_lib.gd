extends RefCounted
class_name CityToolLib

### "Imports": ToolLib
const ToolState := ToolLib.ToolState
const StateDuplicatingUndoableTool := ToolLib.StateDuplicatingUndoableTool


class StreetToolState extends ToolState:
	var curve := Curve3D.new()


class StreetTool extends StateDuplicatingUndoableTool:
	signal curve_changed(p_curve_copy: Curve3D)
	
	func _init():
		_state = StreetToolState.new()
	
	func get_state() -> StreetToolState:
		return get_base_type_state() as StreetToolState
		
	func set_state(p_state: StreetToolState) -> void:
		set_base_type_state(p_state)
		
	func get_node_count() -> int:
		return get_state().curve.point_count
		
	func get_last_node_idx() -> int:
		return get_node_count() - 1
		
	func add_node(p_position: Vector3) -> int:
		get_state().curve.add_point(p_position)
		curve_changed.emit(get_state().curve.duplicate(true))
		copy_state_to_undo()
		return get_last_node_idx()
