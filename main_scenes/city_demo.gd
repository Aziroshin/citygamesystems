extends Node3D




class UndoableToolAction:
	var _state: ToolState
	
	func _init(state: ToolState):
		self._state = state
	
	func do() -> UndoableToolAction:
		push_error(
			"Unimplemented `do` method on `%s` " % self.class_name
			+ "object called."
		)
		return UndoableToolAction.new(self._state)

# Obsolete?
#	func undo() -> UndoableToolAction:
#		push_error(
#			"Unimplemented `undo` method on `%s`" % self.class_name
#			+ "object called."
#		)
#		return UndoableToolAction.new(self._state)
		
# Base class used for `.state` in `UndoableTool` classes.
# The state is passed to actions. In order to prevent actions in undo buffers
# from pointing to different state objects, the state object should always
# remain the same for the entire lifetime of the holding tool object.
class ToolState:

	pass
	
# Base class for tools with undo capability.
class UndoableTool:
	var _state: ToolState
	var _undo_buffer: Array[UndoableToolAction]
	var _redo_buffer: Array[UndoableToolAction]


###########################################################################
### CityToolLib
class StreetToolState extends ToolState:
	var curve_idx_tracker := IncrementalId2IndexTracker.new()
	var curve := Curve3D.new()

# Has `_get_state()` which returns `_state` typed as `StreetToolState`.
class StreetToolAction extends UndoableToolAction:
	func _init(state: ToolState):
		super(state)
		
	func _get_state() -> StreetToolState:
		return self._state as StreetToolState


class StreetToolAddPointAction extends StreetToolAction:
	var _point: Vector3
	var _id: int
	var _idx: int
	
	func _init(state: ToolState, point: Vector3, id := -1, idx := -1):
		super(state)
		self._point = point
		self._id = id
		self._idx = idx
		
	func do() -> UndoableToolAction:
		var id: int
		
		if self._id == -1:
			# New point.
			id = _get_state().curve_idx_tracker.append()
			_get_state().curve.add_point(self._point)
		else:
			# Inserting point; probably from an undo operation.
			id = self._id
			_get_state().curve_idx_tracker.insert(self._id, self._idx)
			
			# Figures I can't insert into Curve3D. Also, stuff like tessellate
			# would be rather tedious to handle. This would probably apply to
			# the idea of reversible actions in general. It's probably better to
			# revert to state slices instead.
			#_get_state().curve....
			
		return StreetToolRemovePointAction.new(self._state, id)


class StreetToolRemovePointAction extends StreetToolAction:
	var _point_id: int
	
	func _init(state: ToolState, point_id: int):
		super(state)
		self._point_id = _point_id
		
	func do() -> UndoableToolAction:
		var idx = self._get_state().curve_idx_tracker.get_idx(self._point_id)
		
		if not idx == -1:
			_get_state().curve.remove_point(idx)
			return StreetToolAddPointAction.new(
				self._state,
				_get_state().curve.get_point_position(idx),
				self._point_id,
				idx
			)
			
		assert(false, "We shouldn't get here.")
		return UndoableToolAction.new(self._state)



class StreetTool extends UndoableTool:
	func _get_state() -> StreetToolState:
		return self._state as StreetToolState
	
	func add_point(point: Vector3):
		self._get_state().curve_idx_tracker.append()
		var action := StreetToolAddPointAction.new(self._state, point)
		self._undo_buffer.append(action.do())
		
	func remove_point(idx: int):
		var id := self._get_state().curve_idx_tracker.remove_by_idx(idx)
		var action := StreetToolRemovePointAction.new(self._state, id)
		self._undo_buffer.append(action.do())
		pass
func _ready() -> void:
	pass
