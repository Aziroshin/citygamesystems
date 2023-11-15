extends Node3D


#⚗️ Unfinished draft for undoable tools on the basis of reversible actions.
# However, reverting to state slices might be better when dealing with `Curve3D`.
#
# Notes for a potential later: One idea was that actions would get an opposite
# action (e.g. for `StreetToolAddPointAction` that would be
# `StreetToolRemovePointAction`), either associated with them at the class level
# (would currently need wrapping of some kind for proper typing), or passed as
# an instance to an instance, initialized with the appropriate value, ready to
# have its `.do()` called from the undoing action's `undo()`.
#
# The current version of the draft goes more towards .do() just returning an
# undoable action, however, which would obsolete the .undo methods - it's just
# an action with .do() in one of three situations:
#  - The initial action as it is originally performed.
#  - The undo action of the initial action in the undo buffer.
#  - The undo action of that undo action in the redo buffer.
# Then, from the redo buffer, they would get back into the undo buffer as
# they're being applied as if they were the original action. Rinse and repeat.
#
# The ID system is there to make sure that actions in the undo buffer can safely
# keep referencing the point they're supposed to operate on, even if its idx in
# `Curve3D` changes, without other actions needing to change the idx on other
# actions whenever they cause changes that alter the idx of some points.
# Instead, these changes are kept track of in the `.curve_idx_tracker`, and if
# undo actions are triggered, they can just look up what the current idx for
# their point is via the ID they're holding.

###########################################################################
### ToolLib
class Id2IndexMapper:
	var _map := {}
	var _size := 0
	
	func insert(new_id: int, new_idx: int) -> void:
		for untyped_id in self._map:
			var id: int = untyped_id
			var idx: int = self._map[id]
			
			if idx >= new_idx:
				self._map[id] = idx + 1
		
		self._map[new_id] = new_idx
		self._size += 1
	
	func append(id: int) -> void:
		self.insert(id, self._size)
	
	# Returns -1 if the map doesn't have a `removee_id` key.
	func remove(removee_id: int) -> int:
		if not self._map.has(removee_id):
			return -1
			
		var removee_idx: int = self._map[removee_id]
		
		for untyped_id in self._map:
			var id: int = untyped_id
			var idx: int = self._map[id]
			
			if idx > removee_idx:
				self._map[id] = idx - 1
			
		self._map.erase(removee_id)
		self._size -= 1
		return removee_idx
		
	# Returns -1 if `removee_idx` is not a value in the map.
	func remove_by_idx(removee_idx: int) -> int:
		var removee_id := get_id_by_idx(removee_idx)
		remove(removee_id)
		return removee_id
		
	# Returns -1 if `id` isn't a key in the map.
	func get_idx(id: int) -> int:
		if self._map.has(id):
			return self._map[id]
		return -1
	
	# Returns -1 if not found.
	func get_id_by_idx(prospective_idx: int) -> int:
		for untyped_id in self._map:
			var id: int = untyped_id
			var idx: int = self._map[id]
			
			if prospective_idx == idx:
				return id
		return -1

class IncrementalIntIdGenerator:
	var _counter := 0
	
	func make_new_id() -> int:
		var new_id := self._counter
		self._counter += 1
		return new_id
		
	func get_last_id() -> int:
		return self._counter


class IncrementalId2IndexTracker:
	var _mapper := Id2IndexMapper.new()
	var _id_generator := IncrementalIntIdGenerator.new()
	
	func insert(new_id: int, new_idx: int) -> void:
		self._mapper.insert(new_id, new_idx)
	
	# Returns the ID of the newly added point.
	func append() -> int:
		var new_id := self._id_generator.make_new_id()
		self._mapper.append(new_id)
		return new_id
	
	# Returns -1 if `removee_id` isn't found.
	# Returns the idx of the removed ID otherwise.
	func remove(removee_id: int) -> int:
		return self._mapper.remove(removee_id)
		
	# Returns -1 if `removee_idx` isn't found.
	# Returns the ID of the removed idx otherwise.
	func remove_by_idx(removee_idx: int) -> int:
		return self._mapper.remove_by_idx(removee_idx)
		
	# Returns -1 if `id` isn't found.
	func get_idx(id: int) -> int:
		return self._mapper.get_idx(id)
	
	# Returns -1 if `idx` isn't found.
	func get_id_by_idx(idx: int) -> int:
		return self._mapper.get_id_by_idx(idx)


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
