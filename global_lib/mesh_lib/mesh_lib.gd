extends RefCounted
class_name MeshLib

### Dependencies:
# - CityGeoFuncs.shear_line
# - CityGeoFuncs.get_multi_surface_array_mesh_node
# - CityGeoFuncs.get_grouped_surfaces_by_material_index
	
	
# Base class for ArrayMesh array classes.
class ASegment:
	var _arrays: Array = []
	var _array_vertex := PackedVector3Array():
		set(value):
			self._arrays[ArrayMesh.ARRAY_VERTEX] = value
		get:
			return self._arrays[ArrayMesh.ARRAY_VERTEX]
			
	var _array_normal := PackedVector3Array():
		set(value):
			self._arrays[ArrayMesh.ARRAY_NORMAL] = value
		get:
			return self._arrays[ArrayMesh.ARRAY_NORMAL]
			
	var _array_tex_uv := PackedVector2Array():
		set(value):
			self._arrays[ArrayMesh.ARRAY_TEX_UV] = value
		get:
			return self._arrays[ArrayMesh.ARRAY_TEX_UV]
			
	static func new_from_ASegment(source_segment: ASegment) -> ASegment:
		return ASegment.new(source_segment.copy_arrays())
		
	func _init(
		arrays: Array = [],
		array_vertex: PackedVector3Array = PackedVector3Array()
	):
		_init_arrays(arrays, array_vertex)
		
	func _init_arrays(
		p_arrays: Array = [],
		p_array_vertex: PackedVector3Array = PackedVector3Array(),
		p_array_normal: PackedVector3Array = PackedVector3Array(),
		p_array_tex_uv: PackedVector2Array = PackedVector2Array()
	):
		self._arrays = p_arrays
		self._arrays.resize(ArrayMesh.ARRAY_MAX)
		
		if len(p_array_vertex) > 0 or p_arrays[ArrayMesh.ARRAY_VERTEX] == null:
			self._arrays[ArrayMesh.ARRAY_VERTEX] = p_array_vertex
		if len(p_array_normal) > 0 or p_arrays[ArrayMesh.ARRAY_NORMAL] == null:
			self._arrays[ArrayMesh.ARRAY_NORMAL] = p_array_normal
		if len(p_array_tex_uv) > 0 or p_arrays[ArrayMesh.ARRAY_TEX_UV] == null:
			self._arrays[ArrayMesh.ARRAY_TEX_UV] = p_array_tex_uv
		
	func _update_arrays_from_arrays(
		arrays: Array
	) -> void:
		_update_arrays(
			arrays[ArrayMesh.ARRAY_VERTEX],
			arrays[ArrayMesh.ARRAY_NORMAL],
			arrays[ArrayMesh.ARRAY_TEX_UV]
		)
		
	# Currently doesn't support adding or removing vertices.
	# TODO: Make analogous to _init.
	func _update_arrays(
		source_array_vertex: PackedVector3Array,
		source_array_normal: PackedVector3Array,
		source_array_tex_uv: PackedVector2Array
	) -> void:
		# Checking if they're all equal in size.
		assert(
			[
				len(self._array_vertex),
				len(self._array_normal),
				len(self._array_tex_uv),
				len(source_array_vertex),
				len(source_array_normal),
				len(source_array_tex_uv)
			].reduce(
				# Once one equals check in the chain fails, all subsequent
				# checks will fail as well, because they'll all be comparing
				# to -1. The end result is then also -1, which means they're not
				# all of equal size.
				func(acc, size): if acc == size: return size else: return -1
			) >= 0,
				# Hey, that way it all fits into the assert-statement. :p
				# TODO: Check if this runs even if the assert passes. That
				# 	would be a bit too wasteful for comfort. xD
				"Array sizes not equal: "
				+ "_array_vertex: %s, " % len(self._array_vertex)
				+ "_array_normal: %s, " % len(self._array_normal)
				+ "_array_tex_uv: %s, " % len(self._array_tex_uv)
				+ "source_array_vertex: %s, " % len(source_array_vertex)
				+ "source_array_normal: %s, " % len(source_array_normal)
				+ "source_array_tex_uv: %s." % len(source_array_tex_uv)
		)
		
		for idx in range(len(source_array_vertex)):
			self._array_vertex[idx] = source_array_vertex[idx]
			self._array_normal[idx] = source_array_normal[idx]
			self._array_tex_uv[idx] = source_array_tex_uv[idx]
			
	# TODO
	func _update_metadata():
		push_error("Unimplemented called.")
		pass
		
	func _update_from_ASegment(segment: ASegment):
		_update_arrays(
			segment.get_array_vertex(),
			segment.get_array_normal(),
			segment.get_array_tex_uv()
		)
		# _update_metadata()  # TODO
		
	# TODO
	func _get_metadata():
		push_error("Unimplemented called.")
		pass
			
	func get_array_vertex() -> PackedVector3Array:
		return self._array_vertex
		
	func get_array_normal() -> PackedVector3Array:
		return self._array_normal
		
	func get_array_tex_uv() -> PackedVector2Array:
		return self._array_tex_uv
		
	func get_arrays() -> Array:
		return self._arrays
		
	func copy_arrays() -> Array:
		return self._arrays.duplicate(true)
		
	# TODO [prio:low]: Same for normal and tex_uv.
	func copy_inverted_array_vertex() -> PackedVector3Array:
		var inverted_array_vertex_copy := PackedVector3Array()
		inverted_array_vertex_copy.resize(len(self._array_vertex))
		for idx in range(0, len(self._array_vertex)):
			inverted_array_vertex_copy[idx] = self._array_vertex[len(_array_vertex) - idx - 1]
		return inverted_array_vertex_copy
		
	func copy_as_ASegment() -> ASegment:
		return ASegment.new_from_ASegment(self)
		
		
class SegmentMutator:
	var segment: ASegment
	enum VectorComponentIndex {
		X,
		Y,
		Z
	}
	
	static func _swap_vector3_components(
		array: PackedVector3Array,
		comp_idx_a,
		comp_idx_b
	) -> void:
		# Get the remaining third idx that hasn't been specified.
		var comp_idx_c = [0, 1, 2].filter(func(a): return a != comp_idx_a and a != comp_idx_b)[0]
		
		for idx in range(0, len(array)):
			var new_vector := Vector3()
			var unswapped := array[idx]
			
			new_vector[comp_idx_a] = unswapped[comp_idx_b]
			new_vector[comp_idx_b] = unswapped[comp_idx_a]
			new_vector[comp_idx_c] = unswapped[comp_idx_c]
			
			array[idx] = new_vector
		
	
	func _init(segment_to_mutate: ASegment):
		self.segment = segment_to_mutate
	
	func multiply_vertices_by_vector3(vector: Vector3):
		for idx in range(0, len(segment._array_vertex)):
			segment._array_vertex[idx] = segment._array_vertex[idx] * vector
			
	func _multiply_normals_by_vector3(vector: Vector3):
		for idx in range(0, len(segment._array_normal)):
			segment._array_normal[idx] = segment._array_normal[idx] * vector

	func flip_vertices_x() -> void:
		multiply_vertices_by_vector3(Vector3(-1, 1, 1))
		_multiply_normals_by_vector3(Vector3(-1, 1, 1))
		
	func flip_vertices_y() -> void:
		multiply_vertices_by_vector3(Vector3(1, -1, 1))
		_multiply_normals_by_vector3(Vector3(1, -1, 1))
		
	func flip_vertices_z() -> void:
		multiply_vertices_by_vector3(Vector3(1, 1, -1))
		_multiply_normals_by_vector3(Vector3(1, 1, -1))
		
	func translate_vertices(vector: Vector3) -> void:
		var array_vertex := self.segment.get_array_vertex()
		for idx in range(0, len(array_vertex)):
			array_vertex[idx] = array_vertex[idx] + vector
			
	func swap_vertex_components(comp_idx_a: int, comp_idx_b: int):
		_swap_vector3_components(self.segment.get_array_vertex(), comp_idx_a, comp_idx_b)
		_swap_vector3_components(self.segment.get_array_normal(), comp_idx_a, comp_idx_b)
			
			
	# TODO: In-place swapping.
			
	func swap_vertex(idx_1: int, idx_2: int) -> void:
		var array_vertex := self.segment.get_array_vertex()
		var tmp_idx_2_vertex := self.segment._array_vertex[idx_2]
		array_vertex[idx_2] = array_vertex[idx_1]
		array_vertex[idx_1] = tmp_idx_2_vertex
		
	func swap_normal(idx_1: int, idx_2: int) -> void:
		var array_normal := self.segment.get_array_normal()
		var tmp_idx_2_normal := self.segment._array_normal[idx_2]
		array_normal[idx_2] = array_normal[idx_1]
		array_normal[idx_1] = tmp_idx_2_normal
		
	func swap_tex_uv(idx_1: int, idx_2: int) -> void:
		var array_tex_uv := self.segment.get_array_tex_uv()
		var tmp_idx_2_tex_uv := self.segment._array_tex_uv[idx_2]
		array_tex_uv[idx_2] = array_tex_uv[idx_1]
		array_tex_uv[idx_1] = tmp_idx_2_tex_uv
		
	func swap_all(idx_1: int, idx_2: int) -> void:
		swap_vertex(idx_1, idx_2)
		swap_normal(idx_1, idx_2)
		swap_tex_uv(idx_1, idx_2)
		
	# TODO: Make resilient when the array isn't divisible by 3.
	func flip_tris() -> void:
		var array_vertex := self.segment.get_array_vertex()
		for idx in range(0, len(array_vertex), 3):
			swap_all(idx+1, idx+2)
			
			
class IndexChangeTrackingSegmentMutator extends SegmentMutator:
	var index_changes_by_array_vertex_index: PackedInt64Array
	func _init(
		segment_to_mutate,
		index_count: int
	):
		super(segment_to_mutate)
		self.index_changes_by_array_vertex_index.resize(index_count)
		for i in range(index_count):
			self.index_changes_by_array_vertex_index[i] = i
		
	func track_vertex_index_swap(idx_1: int, idx_2: int):
		self.index_changes_by_array_vertex_index[idx_1] = idx_2
		self.index_changes_by_array_vertex_index[idx_2] = idx_1
		
	func swap_vertex(idx_1: int, idx_2: int) -> void:
		super(idx_1, idx_2)
		self.track_vertex_index_swap(idx_1, idx_2)
		
		
# Proxies an `ASegment` for added transform features.
# Our `_array_vertex` array is transformed according to `transform` whenever
# it's accessed, unless `apply_transform_on_access` is set to `false`. In that
# case, `apply_transform` has to be explicitely called for the transform to be
# applied.
class ATransformableSegment extends ASegment:
	var untransformed: ASegment
	var transform: Transform3D
	var offset: Transform3D
	
	func _init(
		untransformed: ASegment,
		transform := Transform3D(),
		apply_all_on_init := true,
	):
		super()
		self.untransformed = untransformed
		self.transform = transform
		
		if apply_all_on_init:
			self.apply_all()
		
	func ensure_equal_array_size():
		self._array_vertex.resize(len(self.untransformed._array_vertex))
		self._array_normal.resize(len(self.untransformed._array_normal))
		self._array_tex_uv.resize(len(self.untransformed._array_tex_uv))
		
	func apply_untransformed() -> void:
		ensure_equal_array_size()
		_update_from_ASegment(self.untransformed)
		
	# Sets recalculated vertices based on `.untransformed` using `.transform`.
	# Normals and UVs are simply copied over.
	func apply_transform() -> void:
		ensure_equal_array_size()
		for idx in range(0, len(self.untransformed._array_vertex)):
			var basis_applied: Vector3 =\
				self.transform.basis * self.untransformed._array_vertex[idx]
			self._array_vertex[idx] = self.transform.origin + basis_applied
			self._array_normal[idx] = self.untransformed._array_normal[idx]
			self._array_tex_uv[idx] = self.untransformed._array_tex_uv[idx]
		apply_offset()
		# TODO: Check if the normals have to be transformed as well.
		
	func apply_offset() -> void:
		ensure_equal_array_size()
		for idx in range (0, len(self._array_vertex)):
			var changed_basis: Vector3 = self.offset.basis * self._array_vertex[idx]
			self._array_vertex[idx] = self.offset.origin + changed_basis
		
	func apply_all() -> void:
		apply_transform()
			
			
class Vertex:
	var transformed_segment: ATransformableSegment  # TODO: Can't this be `ASegment`?
	var untransformed_segment: ASegment
	var array_vertex_indexes: PackedInt64Array
	var vertex_array_primary_index: int
	
	var transformed: Vector3:
		set(value):
			for i in array_vertex_indexes:
				self.transformed_segment._array_vertex[i] = value
		get:
			return self.transformed_segment._array_vertex[vertex_array_primary_index]
			
	var untransformed: Vector3:
		set(value):
			for i in array_vertex_indexes:
				self.untransformed_segment._array_vertex[i] = value
		get:
			return self.untransformed_segment._array_vertex[vertex_array_primary_index]
			
	func _init(
		initial_value: Vector3,
		transformed: ATransformableSegment,
		untransformed: ASegment,
		array_vertex_indexes: PackedInt64Array,
		normals_by_array_vertex_index: PackedVector3Array,
		uvs_by_array_vertex_index: PackedVector2Array
	):
		assert(len(array_vertex_indexes) > 0,\
			"The array_vertex_indexes array must contain at least one index.")
		
		self.array_vertex_indexes = array_vertex_indexes
		update_primary_index()
		self.transformed_segment = transformed
		self.untransformed_segment = untransformed
		
		# Make sure the untransformed vertex array is at least as long as
		# the largest index of our vertex.
		var highest_index := 0
		for index in self.array_vertex_indexes:
			highest_index = max(index, highest_index)
			
		if len(untransformed._array_vertex) <= highest_index:
			untransformed._array_vertex.resize(highest_index + 1)
			untransformed._array_normal.resize(highest_index + 1)
			untransformed._array_tex_uv.resize(highest_index + 1)
		
		# Set the vertex positions of all the indexes of this vertex in the
		# untransformed vertex array.
		var i_array_vertex_indexes := 0
		for index in self.array_vertex_indexes:
			untransformed._array_vertex[index] = initial_value
			untransformed._array_normal[index] =\
				normals_by_array_vertex_index[i_array_vertex_indexes]
			untransformed._array_tex_uv[index] =\
				uvs_by_array_vertex_index[i_array_vertex_indexes]
				
			i_array_vertex_indexes += 1
			
	func update_primary_index() -> void:
		self.vertex_array_primary_index = array_vertex_indexes[0]
		
	func change_tracked_array_vertex_index(old_index: int, new_index: int):
		if old_index not in self.array_vertex_indexes:
			push_error(
				"Attempted changing untracked index: "
				+ "old_index: %s, new_index: %s." % [old_index, new_index]
			)
		var array_vertex_size = len(self.untransformed_segment.get_array_vertex())
		if new_index >=  array_vertex_size:
			push_error("Index specified greater than size of array_vertex. "
			+ "Index: %s, array_vertex size: %s." % [new_index, array_vertex_size])
			
		self.array_vertex_indexes[self.array_vertex_indexes.find(old_index)] = new_index
		
	func change_tracked_array_vertex_indexes(
		new_indexes_by_old: PackedInt64Array
	) -> void:
		# Quite expensive for a sanity check.
		var greatest_old_index := PackedInt64ArrayFuncs.get_max(
			self.array_vertex_indexes
		)
		for old_index in self.array_vertex_indexes:
			if len(new_indexes_by_old) <= greatest_old_index:
				push_error(
					"Greatest old index exceeds size of new indexes array. "
					+ "new indexes array size: %s, " % new_indexes_by_old
					+ "greatest old index: %s." % greatest_old_index
				)
				
			# Using .find every time might be quite expensive. It might be
			# better to just range-loop through `.array_vertex_indexes` and do
			# it here.
			self.change_tracked_array_vertex_index(
				old_index,
				new_indexes_by_old[old_index]
			)
			update_primary_index()
			
	### BEGIN: Normals.
	func get_transformed_normal(array_vertex_index: int) -> Vector3:
		assert(array_vertex_index in self.array_vertex_indexes)
		return self.transformed_segment._array_normal[array_vertex_index]
		
	func get_untransformed_normal(array_vertex_index: int) -> Vector3:
		assert(array_vertex_index in self.array_vertex_indexes)
		return self.untransformed_segment._array_normal[array_vertex_index]
		
	func get_untransformed_normals() -> PackedVector3Array:
		var untransformed_normals := PackedVector3Array()
		for array_vertex_index in self.array_vertex_indexes:
			untransformed_normals.append(
				self.get_untransformed_normal(array_vertex_index)
			)
		return untransformed_normals
		
	func set_untransformed_normal(array_vertex_index: int) -> Vertex:
		assert(array_vertex_index in self.array_vertex_indexes)
		self.untransformed_segment._array_normal[array_vertex_index]
		return self
	### END: Normals.
		
	### BEGIN: UVs.
	func get_transformed_tex_uv(array_vertex_index: int) -> Vector2:
		assert(array_vertex_index in self.array_vertex_indexes)
		return self.transformed_segment._array_tex_uv[array_vertex_index]
		
	func get_untransformed_tex_uv(array_vertex_index: int) -> Vector2:
		assert(array_vertex_index in self.array_vertex_indexes)
		return self.untransformed_segment._array_tex_uv[array_vertex_index]
		
	func get_untransformed_tex_uvs() -> PackedVector2Array:
		var untransformed_tex_uvs := PackedVector2Array()
		for array_vertex_index in self.array_vertex_indexes:
			untransformed_tex_uvs.append(
				self.get_untransformed_tex_uv(array_vertex_index)
			)
		return untransformed_tex_uvs
		
	func set_untransformed_tex_uv(array_vertex_index: int) -> Vertex:
		assert(array_vertex_index in self.array_vertex_indexes)
		self.untransformed_segment._array_tex_uv[array_vertex_index]
		return self
	### END: UVs.
		
	func get_translation_to_transformed_position(position: Vector3) -> Vector3:
		return position - transformed
		
	func translate_to_transformed_position(position: Vector3) -> Vertex:
		untransformed = get_translation_to_transformed_position(position)
		return self
		
	func translate_to_transformed(vertex: Vertex) -> Vertex:
		translate_to_transformed_position(vertex.transformed)
		return self
		
		
# It might be a good idea to make this an array-companion delegate instead
# of a parent class.
class AVertexTrackingSegment extends ATransformableSegment:
	var vertices: Array[Vertex]
	
	func _init(
		transform := Transform3D(),
	):
		super(
			ASegment.new([]),
			transform,
			false
		)
		
	func add_vertex(
		array_vertex_indexes: PackedInt64Array,
		initial_value: Vector3 = Vector3(),
		normals_by_array_vertex_index := PackedVector3Array(),
		uvs_by_array_vertex_index := PackedVector2Array()
	) -> Vertex:
		### BEGIN: Ensure Sanity
		var missing_normals_count := len(array_vertex_indexes) - len(normals_by_array_vertex_index)
		if missing_normals_count > 0:
			var default_normal := Vector3()
			push_error(
				"Missing normals when adding Vertex. Initializing with "
				+ "%s" % default_normal
				)
			for i_missing_normal in range(missing_normals_count):
				normals_by_array_vertex_index.append(default_normal)
			
		var missing_uvs_count := len(array_vertex_indexes) - len(uvs_by_array_vertex_index)
		if missing_uvs_count > 0:
			var default_uv := Vector2()
			push_error(
				"Missing UVs when adding Vertex. Initializing with "
				+ "%s." % default_uv
			)
			for i_missing_uv in range(missing_uvs_count):
				uvs_by_array_vertex_index.append(default_uv)
		### END: Ensure Sanity
			
		var vertex := Vertex.new(
			initial_value,
			self,
			self.untransformed,
			array_vertex_indexes,
			normals_by_array_vertex_index,
			uvs_by_array_vertex_index
		)
		self.vertices.append(vertex)
		
		return vertex
		
	# NOTE: In general, it would be good to make sure changes to the segment
	# always go through overridable methods on the segment. That would be
	# useful for something like `AFaceTrackingSegment`, etc. Then, changes to
	# Vertex or Edge tracking parts of the inheritance chain can be intercepted
	# by sub-classes to do what they need to do to accommodate the change.
		
	func add_vertex_from_vertex_with_new_indexes(
		new_indexes,
		source_vertex: Vertex,
		take_initial_value_from_transformed := false
	) -> Vertex:
		var initial_value := source_vertex.untransformed
		if take_initial_value_from_transformed:
			initial_value = source_vertex.transformed
		
		return add_vertex(
			new_indexes,
			initial_value,
			source_vertex.get_untransformed_normals(),
			source_vertex.get_untransformed_tex_uvs()
		)
		
	func change_tracked_array_vertex_indexes(
		new_indexes_by_old: PackedInt64Array
	):
		for vertex in self.vertices:
			vertex.change_tracked_array_vertex_indexes(new_indexes_by_old)
			
			
class Modifier:
	# @virtual
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		# Perform your modifications here.
		pass
			
			
class AModifiableSegment extends AVertexTrackingSegment:
	var vertices_by_arrax_index: Array[Vertex]
	var modifiers: Array[Modifier]
	# The whole cursor principle is a bit questionable, given that
	# we're working on .untransformed, thus don't have an original
	# version of the segment lying around after applying modifiers
	# anyway, which means re-applying the modifiers would only
	# be useful in niche cases the modifier system wasn't exaclty
	# conceived for.
	# It's probably just better to pop the modifier and keep
	# debugging-relevant information around in an appropriate manner.
	var modifier_cursor: int
		
	func add_modifier(modifier: Modifier) -> void:
		self.modifiers.append(modifier)
		
	func apply_modifiers() -> void:
		if not self.modifier_cursor == len(self.modifiers):
			var mutator := IndexChangeTrackingSegmentMutator.new(
				self.untransformed,
				len(self.untransformed.get_array_vertex())
			)
			for i_modifier in range(self.modifier_cursor, len(self.modifiers)):
				self.modifiers[i_modifier].modify(mutator)
				self.modifier_cursor += 1
			
			self._update_from_ASegment(mutator.segment)
			self.change_tracked_array_vertex_indexes(
				mutator.index_changes_by_array_vertex_index
			)
		
		
	func apply_all() -> void:
		# TODO: See if there isn't a better way to make sure the array is
		# initialized with the untransformed values, but we can still call
		# the modifiers before applying the transform (which happens when
		# calling `super` below).
		# `apply_untransformed` is a bit of a loose part to solve this problem,
		# but it makes sub-classing `ATransformableSegment` a bit more
		# error-prone, and the fact that it's not used on
		# `ATransformableSegment`'s apply_all pipeline is a bit weird.
		# Maybe it doesn't actually belong there, but here.
		apply_untransformed()
		apply_modifiers()
		super()
		
class APoint extends AVertexTrackingSegment:
	var vertex: Vertex
	
	func _init(
		vertex: Vector3,
		normal := Vector3(),
		uv := Vector2()
	):
		self.vertex = add_vertex([0], vertex, [normal], [uv])
		
# Idea:
# One way to have AVertexTrackingSegments with edges and faces is to create further
# subclasses of it that feature these things, which will then be parent classes
# to AQuad and so on.
# Note: Godot's MeshDataTool features edges and faces.
		
		
class ALine extends AModifiableSegment:
	var start: Vertex
	var end: Vertex
	
	static func create_default_normals(
		vertices: PackedVector3Array
	) -> PackedVector3Array:
		var normals := PackedVector3Array()
		var last_vertex := vertices[len(vertices)-1]
		for idx in len(vertices):
			# Normals pointing up - can be recalculated to roof slope later.
			normals.append(Vector3(0, 1, 0))
		return normals
			
	static func create_default_uvs(
		vertices: PackedVector3Array
	) -> PackedVector2Array:
			var uvs := PackedVector2Array()
			var last_vertex := vertices[len(vertices)-1]
			for idx in len(vertices):
				var u: float = last_vertex.x / vertices[idx].x
				var v: float = 1.0
				uvs.append(Vector2(u,v))
			return uvs
			
	func _init(
		start: Vector3,
		end: Vector3,
		# Intended for subclassing use. This enables subclasses to start
		# initializing their geometry on a clean object; `start` and `end` will
		# be Nil.
		_no_vertex_init := false,
		start_normal := Vector3(),
		end_normal := Vector3(),
		start_uv := Vector2(),
		end_uv := Vector2(),
	):
		super()
		if not _no_vertex_init:
			self.start = add_vertex([0], start, [start_normal], [start_uv])
			self.end = add_vertex([1], end, [end_normal], [end_uv])
			apply_all()
			
			
# A line of two or more vertices.
# TODO (maybe):
	# If an array of two or more vertices is specified, it is subdivided according
	# to `subdivisions`. For example: 2 vertices and a subdivision value of `1`
	# would result in a line with 3 vertices. If the array had 3 or more vertices
	# however, `subdivisions` would be ignored and the line would be identical to
	# the specified array.
class ASubdividedLine extends ALine:
	func _init(
		array_vertex: PackedVector3Array,
		array_normal := PackedVector3Array(),
		array_tex_uv := PackedVector2Array()
		# subdivisions := 0
	):
		assert(len(array_vertex) > 1)
		
		super(Vector3(), Vector3(), true)
		
		if len(array_normal) == 0:
			array_normal = create_default_normals(array_vertex)
		if len(array_tex_uv) == 0:
			array_tex_uv = create_default_uvs(array_vertex)
		
		for idx in range(0, len(array_vertex)):
			add_vertex(
				PackedInt64Array([idx]),
				array_vertex[idx],
				PackedVector3Array([array_normal[idx]]),
				PackedVector2Array([array_tex_uv[idx]])
			)
		self.start = vertices[0]
		self.end = vertices[len(vertices)-1]
		
		apply_all()
		
	func copy_as_ASubdividedLine() -> ASubdividedLine:
		return ASubdividedLine.new(
			get_array_vertex().duplicate(),
			get_array_normal().duplicate(),
			get_array_tex_uv().duplicate()
		)
		
		
class AQuad extends AModifiableSegment:
	var bottom_left: Vertex
	var top_left: Vertex
	var top_right: Vertex
	var bottom_right: Vertex
	
	func _init(
		bottom_left: Vector3,
		top_left: Vector3,
		top_right: Vector3,
		bottom_right: Vector3,
		
		bottom_left_normal := Vector3(),
		top_left_normal := Vector3(),
		top_right_normal := Vector3(),
		bottom_right_normal := Vector3(),
		
		bottom_left_uv := Vector2(),
		top_left_uv := Vector2(),
		top_right_uv := Vector2(),
		bottom_right_uv := Vector2(),
	):
		super()
		self.bottom_left = add_vertex(
			[0],
			bottom_left,
			[bottom_left_normal],
			[bottom_left_uv]
		)
		self.top_left = add_vertex(
			[1, 3],
			top_left,
			[top_left_normal, top_left_normal],
			[top_left_uv, top_left_uv]
		)
		self.top_right = add_vertex(
			[4],
			top_right,
			[top_right_normal],
			[top_right_uv]
		)
		self.bottom_right = add_vertex(
			[2, 5],
			bottom_right,
			[bottom_right_normal, bottom_right_normal],
			[bottom_right_uv, bottom_right_uv]
		)
		self.apply_all()
		
		
	func as_ATransformableSegment() -> ATransformableSegment:
		return self
		
		
class ATri extends AModifiableSegment:
	var bottom_left: Vertex
	var top: Vertex
	var bottom_right: Vertex
	
	func _init(
		bottom_left: Vector3,
		top: Vector3,
		bottom_right: Vector3,
		
		bottom_left_normal := Vector3(),
		top_normal := Vector3(),
		bottom_right_normal := Vector3(),
		
		bottom_left_uv := Vector2(),
		top_uv := Vector2(),
		bottom_right_uv := Vector2()
	):
		super()
		self.bottom_left = add_vertex(
			[0],
			bottom_left,
			PackedVector3Array([bottom_left_normal]),
			PackedVector2Array([bottom_left_uv])
		)
		self.top = add_vertex(
			[1],
			top,
			PackedVector3Array([top_normal]),
			PackedVector2Array([top_uv])
		)
		self.bottom_right = add_vertex(
			[2],
			bottom_right,
			PackedVector3Array([bottom_right_normal]),
			PackedVector2Array([bottom_right_uv])
		)
		self.apply_all()
		
# NOTE: AMultiSegment and sub-classes shouldn't alter .untransformed
# directly. Instead, they should get their segments through .get_segments.
# How .get_segments gets their segments is entirely up to the sub-class.
class AMultiSegment extends AModifiableSegment:
	var _array_vertex_index_offset: int = 0
	
	# Override in sub-class.
	func _reset_array_vertex_index_offset() -> void:
		self._array_vertex_index_offset = 0
		
	# Override in sub-class.
	func _reset_modifier_cursor() -> void:
		self.modifier_cursor = 0
	
	# @virtual
	func get_segments() -> Array[AModifiableSegment]:
		return []
	
	func _update_vertices_from_segments() -> void:
		for segment in get_segments():
			for vertex in segment.vertices:
				var updated_indexes := PackedInt64Array()
				for array_vertex_index in vertex.array_vertex_indexes:
					updated_indexes.append(self._array_vertex_index_offset + array_vertex_index)
				add_vertex_from_vertex_with_new_indexes(updated_indexes, vertex)
			self._array_vertex_index_offset += len(segment.untransformed.get_array_vertex())
		_reset_array_vertex_index_offset()
		
	func apply_segments() -> void:
		_update_vertices_from_segments()
		
	func apply_modifiers() -> void:
		super()
		
	func apply_all() -> void:
		apply_segments()
		super()
		# Since multi-segment classes are supposed to be initialized from
		# segments, which will be re-applied each time, we will also want to
		# re-run our modifiers each time.
		# NOTE: This won't mesh well with multi-segments that directly alter
		# their .untransformed without going through the apply_segments
		# pipeline.
		_reset_modifier_cursor()
		
	# @virtual
	func as_AVertexTrackingSegment(do_apply_all := false) -> AVertexTrackingSegment:
		# TODO: Proper implementation. :p
		if do_apply_all:
			apply_all()
		else:
			apply_segments()
		return self
		
		
# Applies segments only once, then clears them, so on subsequent calls of
# .apply_segments only segments that got added since the last .apply_segments
# call will be applied.
# The important part for this to work is to override `clear_segments` in a
# sub-class to make sure the next call to .get_segments will return an empty
# array (unless new segments got added again).
class AFlushingMultiSegment extends AMultiSegment:
	# @virtual
	func clear_segments() -> void:
		pass
		
	func _reset_modifier_cursor() -> void:
		pass
	
	func _reset_array_vertex_index_offset() -> void:
		pass
		
	func apply_all() -> void:
		super()
		clear_segments()
		
		
		
###########################################################################
### Modifier Library
###########################################################################
		
		
class MTranslateVertices extends Modifier:
	var translation: Vector3
	
	func _init(translation: Vector3):
		self.translation = translation
		
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		mutator.translate_vertices(self.translation)
		
		
class MMultiplyVerticesByVector3 extends Modifier:
	var vector: Vector3
	
	func _init(vector: Vector3):
		self.vector = vector
	
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		#mutator.multiply_vertices_by_vector3(self.vector)
		mutator.flip_vertices_x()
		
		
class MFlipVerticesX extends MMultiplyVerticesByVector3:
	func _init():
		self.vector = Vector3(-1, 1, 1)
		
		
class MFlipVerticesYModifier extends MMultiplyVerticesByVector3:
	func _init():
		self.vector = Vector3(1, -1, 1)
		
		
class MFlipVerticesZModifier extends MMultiplyVerticesByVector3:
	func _init():
		self.vector = Vector3(1, 1, -1)
		
		
class MFlipTris extends Modifier:
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		mutator.flip_tris()
		
		
	# Stretch by the specified amount.
	# The thought model is that the specified amount is the absolute difference
	# between the `end` vertex of the line and some other xyz relative to it.
	# The specified amount will be divided by the number of vertices and the
	# result added to each vertex.
class MStretchVerticesByAmount extends Modifier:
	var stretch_amount: Vector3
	
	func _init(stretch_amount: Vector3):
		self.stretch_amount = stretch_amount
		
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		var array_vertex := mutator.segment.get_array_vertex()
		var vertex_count := float(len(array_vertex))
		
		if vertex_count < 2.0:
			push_error(\
				"Attempted to stretch mesh with less than 2 vertices. "
				+ "Returning without stretching, as there's nothing to stretch.")
			return
		assert(vertex_count >= 2.0)
		
		var stretch_amount_per_vertex := stretch_amount / (vertex_count - 1.0)
		
		for idx in range(1, len(array_vertex)):
			var vertex := array_vertex[idx]
			array_vertex[idx] = vertex + stretch_amount_per_vertex
			idx += 1
			
			
class MShearVertices extends Modifier:
	var shear_factor: float
	var axis_factors: Vector3
	
	func _init(
		shear_factor: float,
		axis_factors: Vector3
	):
		self.shear_factor = shear_factor
		self.axis_factors = axis_factors
		
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		# TODO: A version of shear_line that makes it so we can operate on
		#  the array directly without the superfluous loop.
		var idx := 0
		# TODO: Normals might have to be adjusted too. Evaluate.
		for vertex in CityGeoFuncs.shear_line(
			mutator.segment.get_array_vertex(),
			self.shear_factor,
			self.axis_factors
		):
			mutator.segment.get_array_vertex()[idx] = vertex
			idx += 1
			
			
class MInvertSurfaceArrays extends Modifier:
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		mutator.segment.get_array_vertex().reverse()
		mutator.segment.get_array_normal().reverse()
		mutator.segment.get_array_tex_uv().reverse()
			
			
class MYUp extends Modifier:
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		var array_vertex := mutator.segment.get_array_vertex()
		mutator.swap_vertex_components(
			mutator.VectorComponentIndex.Y,
			mutator.VectorComponentIndex.Z
		)
			
			
class MYFlipUVs extends Modifier:
	func modify(mutator: IndexChangeTrackingSegmentMutator) -> void:
		var array_tex_uv := mutator.segment.get_array_tex_uv()
		var y_flipped_uvs = PackedVector2Array()
		for i_tri in range(len(array_tex_uv) / 3):
			array_tex_uv[3*i_tri].y = 1.0 - array_tex_uv[3*i_tri].y
			array_tex_uv[3*i_tri+1].y = 1.0 - array_tex_uv[3*i_tri+1].y
			array_tex_uv[3*i_tri+2].y = 1.0 - array_tex_uv[3*i_tri+2].y
			
			
###########################################################################
### Segment Library
###########################################################################
			
			
class AMultiQuad extends AMultiSegment:
	var base_quads: Array[AQuad]
	
	func add_quad(quad: AQuad):
		self.base_quads.append(quad)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for quad in self.base_quads:
			segments.append(quad)
		return segments
	
	
class AMultiTri extends AMultiSegment:
	var base_tris: Array[ATri]
	
	func add_tri(tri: ATri):
		self.base_tris.append(tri)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for tri in self.base_tris:
			segments.append(tri)
		return segments
	
	
class AFlushingMultiTri extends AFlushingMultiSegment:
	var _flushable_base_tris: Array[ATri] = []
	
	func add_tri(tri: ATri):
		self._flushable_base_tris.append(tri)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for tri in self._flushable_base_tris:
			segments.append(tri)
		# This should return an empty array if called again after .apply_all
		# has finished for the first time.
		return segments
		
	func clear_segments() -> void:
		self._flushable_base_tris = []
	
	
class LineVertexArrayChecker:
	const CLASS_NAME := "LineVertexArrayChecker"
	
	var class_designation: String
	var array1_name: String
	var array2_name: String
	var arrays_not_same_size_error_description :=\
		"%s and %s need to be of the same size.%s"
	var error_messages := PackedStringArray()
	var error_message:
		set(value):
			# Read-only.
			push_warning("Attempt to set read-only value for `error_message` in"
				+ " `%s` class (or subclass)." % CLASS_NAME)
		get:
			return " -- ".join(error_messages)
		
	var extra_verbose := false
	var arrays_set := false
	var is_ok: bool:
		set(value):
			# Read-only.
			push_warning("Attempt to set read-only value for `has_error` in"
				+ " `%s` class (or subclass)." % CLASS_NAME) 
		get:
			return len(error_messages) == 0
	
	func _init(
		class_designation: String,
		array1_name := "array1",
		array2_name := "array2",
		extra_verbose := false
	):
		self.class_designation = class_designation
		self.array1_name = array1_name
		self.array2_name = array2_name
		self.extra_verbose = extra_verbose
		
	func _append_arrays_to_error_message(
		error_message: String,
		array1: PackedVector3Array,
		array2: PackedVector3Array
	) -> String:
		return error_message + " array1: %s. array2: %s." % [array1, array2]
		
	func error_if_not_same_size(
		array1: PackedVector3Array,
		array2: PackedVector3Array
	) -> String:
		if len(array1) == len(array1):
			return ""
		var error_details :=\
			" Happened in `%s` (or subclass)." % self.class_designation\
			+ " %s size: %s." % [self.array1_name, len(array1)]\
			+ " %s size: %s." % [self.array2_name, len(array2)]
		if self.extra_verbose:
			error_details = _append_arrays_to_error_message(
				error_details,
				array1,
				array2
			)
		push_error(error_details)
		error_messages.append(error_details)
		return error_details
		
		
class AHorizontallyFoldedTriangle extends AMultiSegment:
	var _side_arrays_error := LineVertexArrayChecker.new(
		"AHorizontallyFoldedTriangle",  # Class name.
		"left side vertex array",
		"right side vertex array"
	)
	
	var left_line: PackedVector3Array
	var right_line: PackedVector3Array
	var base_quads: Array[AQuad]
	var tip_tri: ATri
	
	# TODO: Add support for empty left and right side vertex arrays.
	func _init(
		left_side_vertices: PackedVector3Array,
		right_side_vertices: PackedVector3Array
	):
#		self._side_arrays_error.error_if_not_same_size(
#			self.left_side_vertices,
#			self.right_side_vertices
#		)
#		assert(self._side_arrays_error.is_ok, self._side_arrays_error.error_message)
		self.left_line = left_side_vertices
		self.right_line = right_side_vertices
		
		super()
		
		# TODO: Handle inappropriate number of vertices, e.g. len == 1.
		#  Probably handle that using the same pattern used for the "not same
		#  size" array error.
		var vertex_count := len(left_line)
		var number_of_segments_created: int = 0
		# E.g. if `vertex_count` is 4 this will be 1, if it's 7 it'll be 2.
		# It's always the tip triangle at a minimum, with any further segment
		# being a base quad (if there are any).
		var number_of_segments_to_create: int = vertex_count - 1
		
		# We have base quads. Let's create them before we create the tip, so we
		# can construct from the "bottom left" vertex up.
		# If there are only three vertices, skip this.
		while number_of_segments_to_create - number_of_segments_created > 1:
			self.base_quads.append(AQuad.new(
				self.left_line[number_of_segments_created], # bottom_left
				self.left_line[number_of_segments_created+1], # top_left
				self.right_line[number_of_segments_created+1], # top_right
				self.right_line[number_of_segments_created] # bottom_right
			))
			number_of_segments_created += 1
			
		# Make the triangular tip. If there are only three vertices, this will
		# be the entire segment.
			self.tip_tri = ATri.new(
				self.left_line[number_of_segments_created], # left
				self.left_line[number_of_segments_created+1], # tip
				self.right_line[number_of_segments_created] # right
			)
			number_of_segments_created += 1
			
			
	func get_segments() -> Array[AModifiableSegment]:
		# TODO: `base_quads.duplicate` isn't working for some reason. When
		# subsequently calling .append, the array stays empty.
		var segments := super()
		for quad in self.base_quads:
			segments.append(quad)
		segments.append(self.tip_tri)
		return segments
		
		
class AHorizontallyFoldedPlane extends AMultiSegment:
	var _side_arrays_error := LineVertexArrayChecker.new(
		"AHorizontallyFoldedPlane", # Class name.
		"left side vertex array",
		"right side vertex array"
	)
	
	var left: Array[Vertex]
	var right: Array[Vertex]
	var quads: Array[AQuad]
	var top_quad: AQuad
	var bottom_quad: AQuad
	
	func _init(
		left_side_vertices: PackedVector3Array,
		right_side_vertices: PackedVector3Array
	):
		self._side_arrays_error.error_if_not_same_size(
			left_side_vertices,
			right_side_vertices
		)
		assert(self._side_arrays_error.is_ok, self._side_arrays_error.error_message)
		
		super()
		
		# TODO: Handle inappropriate number of vertices, e.g. len == 1.
		for idx in range(0, len(left_side_vertices) - 1):
			self.quads.append(AQuad.new(
				left_side_vertices[idx], # bottom_left
				left_side_vertices[idx+1], # top_left
				right_side_vertices[idx+1], # top_right
				right_side_vertices[idx] # bottom_right
			))
			
		# TODO: Add support for empty left and right side vertiex arrays.
		self.bottom_quad = quads[0]
		self.top_quad = quads[len(quads)-1]
		
		apply_all()
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for quad in self.quads:
			segments.append(quad)
		return segments
		
		
class AFoldedPlane extends AMultiSegment:
	var strips: Array[AHorizontallyFoldedPlane] = []
	
	func _init(
		outer_left_outline: ASubdividedLine,
		outer_right_outline: ASubdividedLine,
		bottom_outline: ASubdividedLine,
		top_outline: ASubdividedLine
	):
		super()
		var last_idx := len(bottom_outline.get_array_vertex()) - 1
		var left_outline := outer_left_outline.copy_as_ASubdividedLine()
		for idx in range(0, last_idx):
			var outer_bottom_vertex := outer_right_outline.start.transformed
			var inner_bottom_vertex := bottom_outline.vertices[idx+1].transformed
			
			var right_outline := outer_right_outline.copy_as_ASubdividedLine()
			right_outline.add_modifier(MTranslateVertices.new(
				-(outer_bottom_vertex - inner_bottom_vertex)
			))
			
			# TODO [bug]: Without this, weird results happen. However, the
			#	modifier pipeline should provide the same result without it.
			#	.apply_all produces the same (bugged) result, so the problem is
			#	probably somewhere in the modifier system or the modifiers
			#	involved.
			right_outline.apply_modifiers()
			
			right_outline.add_modifier(MStretchVerticesByAmount.new(
				top_outline.vertices[idx+1].transformed\
				- right_outline.end.transformed
			))
			right_outline.apply_all()
			
			# NOTE: It might be wise to check whether the right outline and
			# the outer right line are identical when it's the last pass, since
			# they should be. If they aren't, it's an error in this here function.
			# This woud be more of a test/assert level thing, though.
			
			self.strips.append(AHorizontallyFoldedPlane.new(
				left_outline.get_array_vertex(),
				right_outline.get_array_vertex()
			))
		apply_all()
			
#	func get_segments() -> Array[ATransformableSegment]:
#		return self.strips as Array[ATransformableSegment]
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for strip in self.strips:
			segments.append(strip)
		return segments
		
		
class Surface:
	# @virtual
	func get_mesh_instance_3d() -> MeshInstance3D:
		return MeshInstance3D.new()
		
		
class STris extends Surface:
	var tris: AFlushingMultiTri
	var material_indices: PackedInt64Array
	var materials: Array[Material]
	
	func _init(
		tris: AFlushingMultiTri,
		material_indices: PackedInt64Array,
		materials: Array[Material] = []
	):
		self.tris = tris
		self.materials = materials
		self.material_indices = get_inverted_material_indices(material_indices)
		
	func get_mesh_instance_3d() -> MeshInstance3D:
		var grouped_surface_arrays := CityGeoFuncs.get_grouped_surfaces_by_material_index(
			material_indices,
			self.tris.get_arrays()
		)
		var instance_3d := CityGeoFuncs.get_multi_surface_array_mesh_node(
			grouped_surface_arrays
		)
		for i_material in range(len(materials)):
			instance_3d.mesh.surface_set_material(i_material, materials[i_material])
		
		return instance_3d
		
	func add(addee: STris) -> void:
		var vertices := addee.tris.get_array_vertex()
		var normals := addee.tris.get_array_normal()
		var uvs := addee.tris.get_array_tex_uv()
		
		assert(len(vertices) % 3 == 0)
		
		for i_tri in range(0, len(vertices) / 3.0):
			var offset := i_tri * 3
			var tri := ATri.new(
				vertices[offset],
				vertices[offset+1],
				vertices[offset+2],

				normals[offset],
				normals[offset+1],
				normals[offset+2],

				uvs[offset],
				uvs[offset+1],
				uvs[offset+2]
			)
			self.tris.add_tri(tri)
		self.tris.apply_all()
		
		for addee_material in addee.materials:
			self.materials.append(addee_material)
		for addee_material_index in addee.material_indices:
			self.material_indices.append(addee_material_index)
			
	static func get_inverted_material_indices(
		material_indices: PackedInt64Array
	):
		var inverted_material_indices := PackedInt64Array()
		var length := len(material_indices)
		for i_index in range(length):
			var i_index_inverted := length - i_index - 1
			inverted_material_indices.append(material_indices[i_index_inverted])
		return inverted_material_indices
