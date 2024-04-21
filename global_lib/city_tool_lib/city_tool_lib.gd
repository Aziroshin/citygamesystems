extends RefCounted
class_name CityToolLib

### "Imports": ToolLib
const ToolState := ToolLib.ToolState
const StateDuplicatingUndoableTool := ToolLib.StateDuplicatingUndoableTool


class NodeFinalization:
	var handle_in := false
	var handle_out := false
	var point := false


class CurveToolState extends ToolState:
	var curve := Curve3D.new()
	var node_finalizations: Array[NodeFinalization] = []


class CurveCursor extends RefCounted:
	const READ_ONLY_ERR := "Attempted to set read-only property."
	var _curve: Curve3D
	var current_idx := 0
	
	
	var previous_idx_ro: int:
		get:
			return current_idx - 1
		set(p_value):
			push_error(READ_ONLY_ERR)
	var next_idx_ro: int:
		get:
			return current_idx + 1
		set(p_value):
			push_error(READ_ONLY_ERR)
	var previous_position_ro: Vector3:
		get:
			return _curve.get_point_position(previous_idx_ro)
		set(p_value):
			push_error(READ_ONLY_ERR)
	var current_position_ro: Vector3:
		get:
			return _curve.get_point_position(current_idx)
		set(p_value):
			push_error(READ_ONLY_ERR)
	var next_position_ro: Vector3:
		get:
			return _curve.get_point_position(next_idx_ro)
		set(p_value):
			push_error(READ_ONLY_ERR)
		
	
	func _init(p_curve: Curve3D):
		_curve = p_curve
	

class CurveTool extends StateDuplicatingUndoableTool:
	# Since the idea of one atomic change is different for the tool than
	# it is for `Curve3D`, instead of the curve's signal we use our own.
	## Emitted when there are relevant changes to the curve.
	signal curve_changed(p_curve_copy: Curve3D)
	# Those two constants should be used when dealing with `.finalized` values
	# in order to make code more readable. They're not in the `NodeFinalization`
	# class to make it all a little more straight forward when implementing
	# nodes extending this here class.
	const UNFINALIZED := false
	const FINALIZED := true
	var first_in_point_position_default := Vector3(5.0, 0.0, 5.0)
	var first_out_point_position_default := -Vector3(5.0, 0.0, 5.0)

	func _get_curve_tool_type_state() -> CurveToolState:
		return get_base_type_state() as CurveToolState

	func _set_curve_tool_type_state(p_state: CurveToolState) -> void:
		set_base_type_state(p_state)

	func emit_curve_changed() -> void:
		curve_changed.emit(_get_curve_tool_type_state().curve.duplicate(true))

	func is_in_node_adding_mode() -> bool:
		return\
		get_node_count() == 0\
		or _get_curve_tool_type_state().node_finalizations[get_last_node_idx()].handle_out

	func get_node_count() -> int:
		return _get_curve_tool_type_state().curve.point_count

	func get_last_node_idx() -> int:
		if get_node_count() == 0:
			return 0
		else:
			return get_node_count() - 1

	func add_node(
		p_position: Vector3,
		p_finalized: bool,
	) -> int:
		var state := _get_curve_tool_type_state()
		_get_curve_tool_type_state().curve.add_point(p_position)
		var idx := get_last_node_idx()
		
		if idx == 0:
			_get_curve_tool_type_state().curve.set_point_in(idx, first_in_point_position_default)
			_get_curve_tool_type_state().curve.set_point_out(idx, first_out_point_position_default)
		else:
			var in_point_position\
			:= state.curve.get_point_out(idx - 1)\
			+ state.curve.get_point_position(idx - 1)\
			- state.curve.get_point_position(idx)
			
			_get_curve_tool_type_state().curve.set_point_in(idx, in_point_position)
			_get_curve_tool_type_state().curve.set_point_out(idx, -in_point_position)
		state.node_finalizations.append(NodeFinalization.new())
		state.node_finalizations[idx].point = p_finalized
		
		emit_curve_changed()
		copy_state_to_undo()
		return get_last_node_idx()

	func set_node_position(
		p_idx: int,
		p_position: Vector3,
		p_finalized: bool
	) -> void:
		_get_curve_tool_type_state().curve.set_point_position(p_idx, p_position)
		_get_curve_tool_type_state().node_finalizations[p_idx].point = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()

	func set_node_handle_out_point(
		p_idx: int,
		p_position: Vector3,
		p_finalized: bool
	) -> void:
		_get_curve_tool_type_state().curve.set_point_out(p_idx, p_position)
		_get_curve_tool_type_state().node_finalizations[p_idx].handle_out = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()

	func set_node_handle_in_point(
		p_idx: int,
		p_position: Vector3,
		p_finalized: bool
	) -> void:
		_get_curve_tool_type_state().curve.set_point_in(p_idx, p_position)
		_get_curve_tool_type_state().node_finalizations[p_idx].handle_in = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()


class StreetToolState extends CurveToolState:
	pass


class StreetTool extends CurveTool:
	func _init():
		_state = StreetToolState.new()
	
	func get_state() -> StreetToolState:
		return _get_curve_tool_type_state() as StreetToolState
		
	func set_state(p_state: StreetToolState) -> void:
		_set_curve_tool_type_state(p_state)


class CurveLayoutToolState extends CurveToolState:
	var max_height: float
	var snap_nodes: bool
	var snap_curve: bool

	func _init():
		# These values will probably have to be gotten in other ways, e.g.
		# by default adopting the height of adjacent layouts and remembering
		# the snap setting from when last the tool was used.
		max_height = 3.0
		snap_nodes = true
		snap_curve = true


class PolygonLayoutToolState extends ToolState:
	pass


class CurveLayoutTool extends CurveTool:
	func _init():
		_state = CurveLayoutToolState.new()

	func get_state() -> CurveLayoutToolState:
		return _get_curve_tool_type_state() as CurveLayoutToolState

	func set_state(p_state: CurveLayoutToolState) -> void:
		_set_curve_tool_type_state(p_state)


class PolygonLayoutTool extends StateDuplicatingUndoableTool:
	func _init():
		_state = CurveLayoutToolState.new()

	func get_state() -> PolygonLayoutToolState:
		return get_base_type_state() as PolygonLayoutToolState

	func set_state(p_state: PolygonLayoutToolState) -> void:
		set_base_type_state(p_state)
