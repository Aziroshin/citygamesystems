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
		
	func get_node_count() -> int:
		# The baked points don't correspond to control nodes in the sense
		# that we'd want them for streets, so that doesn't work.
		# What we'd need here is a way to get the points as we've added them.
		# We might have to make something like a "CurveControl3D".
		return get_state().curve.point_count
		
	func get_last_node_idx() -> int:
		return get_node_count() - 1
		
	func add_node(position: Vector3) -> int:
		get_state().curve.add_point(position)
		copy_state_to_undo()
		return get_last_node_idx()
