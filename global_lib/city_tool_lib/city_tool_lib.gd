extends RefCounted
class_name CityToolLib

### "Imports": ToolLib
const ToolState := ToolLib.ToolState
const StateDuplicatingUndoableTool := ToolLib.StateDuplicatingUndoableTool


class NodeFinalization:
	var handle_in := false
	var handle_out := false
	var point := false


class StreetToolState extends ToolState:
	var curve := Curve3D.new()
	var node_finalizations: Array[NodeFinalization] = []


class StreetTool extends StateDuplicatingUndoableTool:
	# Since the idea of one atomic change is different for the tool than
	# it is for `Curve3D`, instead of the curve's signal we use our own.
	## Emitted when there are relevant changes to the curve.
	signal curve_changed(p_curve_copy: Curve3D)
	# Those two constants should be used when dealing with `.finalized` values
	# in order to make code more readable. They're not in the `Finalized` class
	# to make it all a little more straight forward when implementing nodes
	# extending this here class.
	const UNFINALIZED := false
	const FINALIZED := true
	
	func _init():
		_state = StreetToolState.new()
	
	func is_in_node_adding_mode() -> bool:
		return\
		get_node_count() == 0\
		or get_state().node_finalizations[get_last_node_idx()].handle_out
	
	func emit_curve_changed() -> void:
		curve_changed.emit(get_state().curve.duplicate(true))
	
	func get_state() -> StreetToolState:
		return get_base_type_state() as StreetToolState
		
	func set_state(p_state: StreetToolState) -> void:
		set_base_type_state(p_state)
		
	func get_node_count() -> int:
		return get_state().curve.point_count
		
	func get_last_node_idx() -> int:
		if get_node_count() == 0:
			return 0
		else:
			return get_node_count() - 1
		
	func add_node(
		p_position: Vector3,
		p_finalized: bool
	) -> int:
		var state := get_state()
		get_state().curve.add_point(p_position)
		var idx := get_last_node_idx()
		
		if idx == 0:
			get_state().curve.set_point_in(idx, Vector3(5.0, 0.0, 5.0))
			get_state().curve.set_point_out(idx, -Vector3(5.0, 0.0, 5.0))
		else:
			var in_point_position\
			:= state.curve.get_point_out(idx - 1)\
			+ state.curve.get_point_position(idx - 1)\
			- state.curve.get_point_position(idx)
			
			get_state().curve.set_point_in(idx, in_point_position)
			get_state().curve.set_point_out(idx, -in_point_position)
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
		get_state().curve.set_point_position(p_idx, p_position)
		get_state().node_finalizations[p_idx].point = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()
		
	func set_node_handle_out_point(
		p_idx: int,
		p_position: Vector3,
		p_finalized: bool
	) -> void:
		get_state().curve.set_point_out(p_idx, p_position)
		get_state().node_finalizations[p_idx].handle_out = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()
		
	func set_node_handle_in_point(
		p_idx: int,
		p_position: Vector3,
		p_finalized: bool
	) -> void:
		get_state().curve.set_point_out(p_idx, p_position)
		get_state().node_finalizations[p_idx].handle_in = p_finalized
		emit_curve_changed()
		if p_finalized:
			copy_state_to_undo()
