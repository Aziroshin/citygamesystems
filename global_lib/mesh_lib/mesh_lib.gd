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
		set(p_value):
			_arrays[ArrayMesh.ARRAY_VERTEX] = p_value
		get:
			return _arrays[ArrayMesh.ARRAY_VERTEX]
			
	var _array_normal := PackedVector3Array():
		set(p_value):
			_arrays[ArrayMesh.ARRAY_NORMAL] = p_value
		get:
			return _arrays[ArrayMesh.ARRAY_NORMAL]
			
	var _array_tex_uv := PackedVector2Array():
		set(p_value):
			_arrays[ArrayMesh.ARRAY_TEX_UV] = p_value
		get:
			return _arrays[ArrayMesh.ARRAY_TEX_UV]
			
	static func new_from_ASegment(p_source_segment: ASegment) -> ASegment:
		return ASegment.new(p_source_segment.copy_arrays())
		
	func _init(
		p_arrays: Array = [],
		p_array_vertex: PackedVector3Array = PackedVector3Array()
	):
		_init_arrays(p_arrays, p_array_vertex)
		
	func _init_arrays(
		p_arrays: Array = [],
		p_array_vertex: PackedVector3Array = PackedVector3Array(),
		p_array_normal: PackedVector3Array = PackedVector3Array(),
		p_array_tex_uv: PackedVector2Array = PackedVector2Array()
	):
		_arrays = p_arrays
		_arrays.resize(ArrayMesh.ARRAY_MAX)
		
		if len(p_array_vertex) > 0 or p_arrays[ArrayMesh.ARRAY_VERTEX] == null:
			_arrays[ArrayMesh.ARRAY_VERTEX] = p_array_vertex
		if len(p_array_normal) > 0 or p_arrays[ArrayMesh.ARRAY_NORMAL] == null:
			_arrays[ArrayMesh.ARRAY_NORMAL] = p_array_normal
		if len(p_array_tex_uv) > 0 or p_arrays[ArrayMesh.ARRAY_TEX_UV] == null:
			_arrays[ArrayMesh.ARRAY_TEX_UV] = p_array_tex_uv
		
	func _update_arrays_from_arrays(
		p_arrays: Array
	) -> void:
		_update_arrays(
			p_arrays[ArrayMesh.ARRAY_VERTEX],
			p_arrays[ArrayMesh.ARRAY_NORMAL],
			p_arrays[ArrayMesh.ARRAY_TEX_UV]
		)
		
	# Currently doesn't support adding or removing vertices.
	# TODO: Make analogous to _init.
	func _update_arrays(
		p_source_array_vertex: PackedVector3Array,
		p_source_array_normal: PackedVector3Array,
		p_source_array_tex_uv: PackedVector2Array
	) -> void:
		# Checking if they're all equal in size.
		assert(
			[
				len(_array_vertex),
				len(_array_normal),
				len(_array_tex_uv),
				len(p_source_array_vertex),
				len(p_source_array_normal),
				len(p_source_array_tex_uv)
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
				+ "_array_vertex: %s, " % len(_array_vertex)
				+ "_array_normal: %s, " % len(_array_normal)
				+ "_array_tex_uv: %s, " % len(_array_tex_uv)
				+ "p_source_array_vertex: %s, " % len(p_source_array_vertex)
				+ "p_source_array_normal: %s, " % len(p_source_array_normal)
				+ "p_source_array_tex_uv: %s." % len(p_source_array_tex_uv)
		)
		
		for idx in range(len(p_source_array_vertex)):
			_array_vertex[idx] = p_source_array_vertex[idx]
			_array_normal[idx] = p_source_array_normal[idx]
			_array_tex_uv[idx] = p_source_array_tex_uv[idx]
			
	# TODO
	func _update_metadata():
		push_error("Unimplemented called.")
		pass
		
	func _update_from_ASegment(p_source_segment: ASegment):
		_update_arrays(
			p_source_segment.get_array_vertex(),
			p_source_segment.get_array_normal(),
			p_source_segment.get_array_tex_uv()
		)
		# TODO: _update_metadata()
		
	# TODO
	func _get_metadata():
		push_error("Unimplemented called.")
		pass
			
	func get_array_vertex() -> PackedVector3Array:
		return _array_vertex
		
	func get_array_normal() -> PackedVector3Array:
		return _array_normal
		
	func get_array_tex_uv() -> PackedVector2Array:
		return _array_tex_uv
		
	func get_arrays() -> Array:
		return _arrays
		
	func copy_arrays() -> Array:
		return _arrays.duplicate(true)
		
	# TODO [prio:low]: Same for normal and tex_uv.
	func copy_inverted_array_vertex() -> PackedVector3Array:
		var inverted_array_vertex_copy := PackedVector3Array()
		inverted_array_vertex_copy.resize(len(_array_vertex))
		for idx in range(0, len(_array_vertex)):
			inverted_array_vertex_copy[idx]\
			= _array_vertex[len(_array_vertex) - idx - 1]
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
		p_array: PackedVector3Array,
		p_component_idx_a,
		p_component_idx_b
	) -> void:
		# Get the remaining third idx that hasn't been specified.
		var component_idx_c\
		= [0, 1, 2].filter(
			func(component_idx):
				return\
				not component_idx == p_component_idx_a\
				and not component_idx == p_component_idx_b\
		)[0]
		
		for idx in range(0, len(p_array)):
			var new_vector := Vector3()
			var unswapped := p_array[idx]
			
			new_vector[p_component_idx_a] = unswapped[p_component_idx_b]
			new_vector[p_component_idx_b] = unswapped[p_component_idx_a]
			new_vector[component_idx_c] = unswapped[component_idx_c]
			
			p_array[idx] = new_vector
		
	
	func _init(p_segment_to_mutate: ASegment):
		self.segment = p_segment_to_mutate
	
	func multiply_vertices_by_vector3(p_vector: Vector3):
		for idx in range(0, len(segment._array_vertex)):
			segment._array_vertex[idx] = segment._array_vertex[idx] * p_vector
			
	func _multiply_normals_by_vector3(p_vector: Vector3):
		for idx in range(0, len(segment._array_normal)):
			segment._array_normal[idx] = segment._array_normal[idx] * p_vector

	func flip_vertices_x() -> void:
		multiply_vertices_by_vector3(Vector3(-1, 1, 1))
		_multiply_normals_by_vector3(Vector3(-1, 1, 1))
		
	func flip_vertices_y() -> void:
		multiply_vertices_by_vector3(Vector3(1, -1, 1))
		_multiply_normals_by_vector3(Vector3(1, -1, 1))
		
	func flip_vertices_z() -> void:
		multiply_vertices_by_vector3(Vector3(1, 1, -1))
		_multiply_normals_by_vector3(Vector3(1, 1, -1))
		
	func translate_vertices(p_vector: Vector3) -> void:
		var array_vertex := segment.get_array_vertex()
		for idx in range(0, len(array_vertex)):
			array_vertex[idx] = array_vertex[idx] + p_vector
			
	func swap_vertex_components(p_comp_idx_a: int, p_comp_idx_b: int):
		_swap_vector3_components(
			segment.get_array_vertex(),
			p_comp_idx_a,
			p_comp_idx_b
		)
		_swap_vector3_components(
			segment.get_array_normal(),
			p_comp_idx_a,
			p_comp_idx_b
		)
			
			
	# TODO: In-place swapping.
			
	func swap_vertex(p_idx_1: int, p_idx_2: int) -> void:
		var array_vertex := self.segment.get_array_vertex()
		var tmp_idx_2_vertex := self.segment._array_vertex[p_idx_2]
		array_vertex[p_idx_2] = array_vertex[p_idx_1]
		array_vertex[p_idx_1] = tmp_idx_2_vertex
		
	func swap_normal(p_idx_1: int, p_idx_2: int) -> void:
		var array_normal := self.segment.get_array_normal()
		var tmp_idx_2_normal := self.segment._array_normal[p_idx_2]
		array_normal[p_idx_2] = array_normal[p_idx_1]
		array_normal[p_idx_1] = tmp_idx_2_normal
		
	func swap_tex_uv(p_idx_1: int, p_idx_2: int) -> void:
		var array_tex_uv := self.segment.get_array_tex_uv()
		var tmp_idx_2_tex_uv := self.segment._array_tex_uv[p_idx_2]
		array_tex_uv[p_idx_2] = array_tex_uv[p_idx_1]
		array_tex_uv[p_idx_1] = tmp_idx_2_tex_uv
		
	func swap_all(p_idx_1: int, p_idx_2: int) -> void:
		swap_vertex(p_idx_1, p_idx_2)
		swap_normal(p_idx_1, p_idx_2)
		swap_tex_uv(p_idx_1, p_idx_2)
		
	# TODO: Make resilient when the array isn't divisible by 3.
	func flip_tris() -> void:
		var array_vertex := self.segment.get_array_vertex()
		for p_idx in range(0, len(array_vertex), 3):
			swap_all(p_idx+1, p_idx+2)
			
			
class IndexChangeTrackingSegmentMutator extends SegmentMutator:
	var index_changes_by_array_vertex_index: PackedInt64Array
	func _init(
		p_segment_to_mutate,
		p_index_count: int
	):
		super(p_segment_to_mutate)
		index_changes_by_array_vertex_index.resize(p_index_count)
		for i in range(p_index_count):
			index_changes_by_array_vertex_index[i] = i
		
	func track_vertex_index_swap(p_idx_1: int, p_idx_2: int):
		self.index_changes_by_array_vertex_index[p_idx_1] = p_idx_2
		self.index_changes_by_array_vertex_index[p_idx_2] = p_idx_1
		
	func swap_vertex(p_idx_1: int, p_idx_2: int) -> void:
		super(p_idx_1, p_idx_2)
		self.track_vertex_index_swap(p_idx_1, p_idx_2)
		
		
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
		p_untransformed: ASegment,
		p_transform := Transform3D(),
		p_apply_all_on_init := true,
	):
		super()
		untransformed = p_untransformed
		transform = p_transform
		
		if p_apply_all_on_init:
			apply_all()
		
	func ensure_equal_array_size():
		_array_vertex.resize(len(untransformed._array_vertex))
		_array_normal.resize(len(untransformed._array_normal))
		_array_tex_uv.resize(len(untransformed._array_tex_uv))
		
	func apply_untransformed() -> void:
		ensure_equal_array_size()
		_update_from_ASegment(untransformed)
		
	# Sets recalculated vertices based on `.untransformed` using `.transform`.
	# Normals and UVs are simply copied over.
	func apply_transform() -> void:
		ensure_equal_array_size()
		for idx in range(0, len(untransformed._array_vertex)):
			var basis_applied: Vector3\
			= transform.basis * untransformed._array_vertex[idx]
			_array_vertex[idx] = transform.origin + basis_applied
			_array_normal[idx] = untransformed._array_normal[idx]
			_array_tex_uv[idx] = untransformed._array_tex_uv[idx]
		apply_offset()
		# TODO: Check if the normals have to be transformed as well.
		
	func apply_offset() -> void:
		ensure_equal_array_size()
		for idx in range (0, len(_array_vertex)):
			var changed_basis: Vector3 = offset.basis * _array_vertex[idx]
			_array_vertex[idx] = offset.origin + changed_basis
		
	func apply_all() -> void:
		apply_transform()
			
			
class Vertex:
	# TODO: Can't this be `ASegment`?
	var transformed_segment: ATransformableSegment  
	var untransformed_segment: ASegment
	var array_vertex_indexes: PackedInt64Array
	var vertex_array_primary_index: int
	
	var transformed: Vector3:
		set(p_value):
			for i in array_vertex_indexes:
				transformed_segment._array_vertex[i] = p_value
		get:
			return\
			transformed_segment._array_vertex[vertex_array_primary_index]
			
	var untransformed: Vector3:
		set(p_value):
			for i in array_vertex_indexes:
				untransformed_segment._array_vertex[i] = p_value
		get:
			return\
			untransformed_segment._array_vertex[vertex_array_primary_index]
			
	func _init(
		p_initial_value: Vector3,
		p_transformed: ATransformableSegment,
		p_untransformed: ASegment,
		p_array_vertex_indexes: PackedInt64Array,
		p_normals_by_array_vertex_index: PackedVector3Array,
		p_uvs_by_array_vertex_index: PackedVector2Array
	):
		assert(
			len(p_array_vertex_indexes) > 0,
			"The array_vertex_indexes array must contain at least one index."
		)
		
		array_vertex_indexes = p_array_vertex_indexes
		update_primary_index()
		transformed_segment = p_transformed
		untransformed_segment = p_untransformed
		
		# Make sure the untransformed vertex array is at least as long as
		# the largest index of our vertex.
		var highest_index := 0
		for index in array_vertex_indexes:
			highest_index = max(index, highest_index)
			
		if len(p_untransformed._array_vertex) <= highest_index:
			p_untransformed._array_vertex.resize(highest_index + 1)
			p_untransformed._array_normal.resize(highest_index + 1)
			p_untransformed._array_tex_uv.resize(highest_index + 1)
		
		# Set the vertex positions of all the indexes of this vertex in the
		# untransformed vertex array.
		var i_array_vertex_indexes := 0
		for index in array_vertex_indexes:
			p_untransformed._array_vertex[index]\
			= p_initial_value
			
			p_untransformed._array_normal[index]\
			= p_normals_by_array_vertex_index[i_array_vertex_indexes]
			
			p_untransformed._array_tex_uv[index]\
			= p_uvs_by_array_vertex_index[i_array_vertex_indexes]
			
			i_array_vertex_indexes += 1
			
	func update_primary_index() -> void:
		vertex_array_primary_index = array_vertex_indexes[0]
		
	func change_tracked_array_vertex_index(p_old_index: int, p_new_index: int):
		if p_old_index not in array_vertex_indexes:
			push_error(
				"Attempted changing untracked index: "
				+ "old_index: %s, new_index: %s." % [p_old_index, p_new_index]
			)
		var array_vertex_size\
			= len(untransformed_segment.get_array_vertex())
		if p_new_index >=  array_vertex_size:
			push_error(
				"Index specified greater than size of array_vertex. "
				+ "Index: %s, array_vertex size: " % p_new_index
				+ "%s." % array_vertex_size
			)
			
		array_vertex_indexes[array_vertex_indexes.find(p_old_index)]\
		= p_new_index
		
	func change_tracked_array_vertex_indexes(
		p_new_indexes_by_old: PackedInt64Array
	) -> void:
		# Quite expensive for a sanity check.
		var greatest_old_index := PackedInt64ArrayFuncs.get_max(
			array_vertex_indexes
		)
		for old_index in array_vertex_indexes:
			if len(p_new_indexes_by_old) <= greatest_old_index:
				push_error(
					"Greatest old index exceeds size of new indexes array. "
					+ "new indexes array size: %s, " % p_new_indexes_by_old
					+ "greatest old index: %s." % greatest_old_index
				)
				
			# Using .find every time might be quite expensive. It might be
			# better to just range-loop through `.array_vertex_indexes` and do
			# it here.
			change_tracked_array_vertex_index(
				old_index,
				p_new_indexes_by_old[old_index]
			)
			update_primary_index()
			
	### BEGIN: Normals.
	func get_transformed_normal(p_array_vertex_index: int) -> Vector3:
		assert(p_array_vertex_index in array_vertex_indexes)
		return transformed_segment._array_normal[p_array_vertex_index]
		
	func get_untransformed_normal(p_array_vertex_index: int) -> Vector3:
		assert(p_array_vertex_index in array_vertex_indexes)
		return untransformed_segment._array_normal[p_array_vertex_index]
		
	func get_untransformed_normals() -> PackedVector3Array:
		var untransformed_normals := PackedVector3Array()
		for array_vertex_index in array_vertex_indexes:
			untransformed_normals.append(
				get_untransformed_normal(array_vertex_index)
			)
		return untransformed_normals
		
#	func set_untransformed_normal(p_array_vertex_index: int) -> Vertex:
#		assert(p_array_vertex_index in array_vertex_indexes)
#		untransformed_segment._array_normal[p_array_vertex_index]
#		return self
	### END: Normals.
		
	### BEGIN: UVs.
	func get_transformed_tex_uv(p_array_vertex_index: int) -> Vector2:
		assert(p_array_vertex_index in array_vertex_indexes)
		return transformed_segment._array_tex_uv[p_array_vertex_index]
		
	func get_untransformed_tex_uv(p_array_vertex_index: int) -> Vector2:
		assert(p_array_vertex_index in array_vertex_indexes)
		return untransformed_segment._array_tex_uv[p_array_vertex_index]
		
	func get_untransformed_tex_uvs() -> PackedVector2Array:
		var untransformed_tex_uvs := PackedVector2Array()
		for array_vertex_index in array_vertex_indexes:
			untransformed_tex_uvs.append(
				get_untransformed_tex_uv(array_vertex_index)
			)
		return untransformed_tex_uvs
		
#	func set_untransformed_tex_uv(p_array_vertex_index: int) -> Vertex:
#		assert(p_array_vertex_index in self.array_vertex_indexes)
#		self.untransformed_segment._array_tex_uv[p_array_vertex_index]
#		return self
	### END: UVs.
		
	func get_translation_to_transformed_position(
		p_position: Vector3
	) -> Vector3:
		return p_position - transformed
		
	func translate_to_transformed_position(p_position: Vector3) -> Vertex:
		untransformed = get_translation_to_transformed_position(p_position)
		return self
		
	func translate_to_transformed(p_vertex: Vertex) -> Vertex:
		translate_to_transformed_position(p_vertex.transformed)
		return self
		
		
# It might be a good idea to make this an array-companion delegate instead
# of a parent class.
class AVertexTrackingSegment extends ATransformableSegment:
	var vertices: Array[Vertex]
	
	func _init(
		p_transform := Transform3D(),
	):
		super(
			ASegment.new([]),
			p_transform,
			false
		)
		
	func add_vertex(
		p_array_vertex_indexes: PackedInt64Array,
		p_initial_value: Vector3 = Vector3(),
		p_normals_by_array_vertex_index := PackedVector3Array(),
		p_uvs_by_array_vertex_index := PackedVector2Array()
	) -> Vertex:
		### BEGIN: Ensure Sanity
		var missing_normals_count\
		:= len(p_array_vertex_indexes) - len(p_normals_by_array_vertex_index)
		
		if missing_normals_count > 0:
			var default_normal := Vector3()
			push_error(
				"Missing normals when adding Vertex. Initializing with "
				+ "%s" % default_normal
				)
			for i_missing_normal in range(missing_normals_count):
				p_normals_by_array_vertex_index.append(default_normal)
		
		var missing_uvs_count\
		:= len(p_array_vertex_indexes) - len(p_uvs_by_array_vertex_index)
		
		if missing_uvs_count > 0:
			var default_uv := Vector2()
			push_error(
				"Missing UVs when adding Vertex. Initializing with "
				+ "%s." % default_uv
			)
			for i_missing_uv in range(missing_uvs_count):
				p_uvs_by_array_vertex_index.append(default_uv)
		### END: Ensure Sanity
		
		var vertex := Vertex.new(
			p_initial_value,
			self,
			untransformed,
			p_array_vertex_indexes,
			p_normals_by_array_vertex_index,
			p_uvs_by_array_vertex_index
		)
		vertices.append(vertex)
		
		return vertex
		
	# NOTE: In general, it would be good to make sure changes to the segment
	# always go through overridable methods on the segment. That would be
	# useful for something like `AFaceTrackingSegment`, etc. Then, changes to
	# Vertex or Edge tracking parts of the inheritance chain can be intercepted
	# by sub-classes to do what they need to do to accommodate the change.
		
	func add_vertex_from_vertex_with_new_indexes(
		p_new_indexes,
		p_source_vertex: Vertex,
		p_take_initial_value_from_transformed := false
	) -> Vertex:
		var initial_value := p_source_vertex.untransformed
		if p_take_initial_value_from_transformed:
			initial_value = p_source_vertex.transformed
		
		return add_vertex(
			p_new_indexes,
			initial_value,
			p_source_vertex.get_untransformed_normals(),
			p_source_vertex.get_untransformed_tex_uvs()
		)
		
	func change_tracked_array_vertex_indexes(
		p_new_indexes_by_old: PackedInt64Array
	):
		for vertex in self.vertices:
			vertex.change_tracked_array_vertex_indexes(p_new_indexes_by_old)
			
			
class Modifier:
	# @virtual
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
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
		
	func add_modifier(p_modifier: Modifier) -> void:
		modifiers.append(p_modifier)
		
	func apply_modifiers() -> void:
		if not modifier_cursor == len(modifiers):
			var mutator := IndexChangeTrackingSegmentMutator.new(
				untransformed,
				len(untransformed.get_array_vertex())
			)
			for i_modifier in range(self.modifier_cursor, len(modifiers)):
				modifiers[i_modifier].modify(mutator)
				modifier_cursor += 1
			
			_update_from_ASegment(mutator.segment)
			change_tracked_array_vertex_indexes(
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
		p_vertex: Vector3,
		p_normal := Vector3(),
		p_uv := Vector2()
	):
		vertex = add_vertex([0], p_vertex, [p_normal], [p_uv])
		
# Idea:
# One way to have AVertexTrackingSegments with edges and faces is to create
# further subclasses of it that feature these things, which will then be parent
# classes to AQuad and so on.
# Note: Godot's MeshDataTool features edges and faces.
		
		
class ALine extends AModifiableSegment:
	var start: Vertex
	var end: Vertex
	
	static func create_default_normals(
		p_vertices: PackedVector3Array
	) -> PackedVector3Array:
		var normals := PackedVector3Array()
		var last_vertex := p_vertices[len(p_vertices)-1]
		for idx in len(p_vertices):
			# Normals pointing up - can be recalculated to roof slope later.
			normals.append(Vector3(0, 1, 0))
		return normals
			
	static func create_default_uvs(
		p_vertices: PackedVector3Array
	) -> PackedVector2Array:
			var uvs := PackedVector2Array()
			var last_vertex := p_vertices[len(p_vertices)-1]
			for idx in len(p_vertices):
				var u: float = last_vertex.x / p_vertices[idx].x
				var v: float = 1.0
				uvs.append(Vector2(u,v))
			return uvs
			
	func _init(
		p_start: Vector3,
		p_end: Vector3,
		# Intended for subclassing use. This enables subclasses to start
		# initializing their geometry on a clean object; `start` and `end` will
		# be Nil.
		p_no_vertex_init := false,
		p_start_normal := Vector3(),
		p_end_normal := Vector3(),
		p_start_uv := Vector2(),
		p_end_uv := Vector2(),
	):
		super()
		if not p_no_vertex_init:
			start = add_vertex([0], p_start, [p_start_normal], [p_start_uv])
			end = add_vertex([1], p_end, [p_end_normal], [p_end_uv])
			apply_all()
			
			
# A line of two or more vertices.
# TODO (maybe):
	# If an array of two or more vertices is specified, it is subdivided
	# according to `subdivisions`. For example: 2 vertices and a subdivision
	# value of `1` would result in a line with 3 vertices. If the array had 3
	# or more vertices however, `subdivisions` would be ignored and the line
	# would be identical to the specified array.
class ASubdividedLine extends ALine:
	func _init(
		p_array_vertex: PackedVector3Array,
		p_array_normal := PackedVector3Array(),
		p_array_tex_uv := PackedVector2Array()
		# subdivisions := 0
	):
		assert(len(p_array_vertex) > 1)
		
		super(Vector3(), Vector3(), true)
		
		if len(p_array_normal) == 0:
			p_array_normal = create_default_normals(p_array_vertex)
		if len(p_array_tex_uv) == 0:
			p_array_tex_uv = create_default_uvs(p_array_vertex)
		
		for idx in range(0, len(p_array_vertex)):
			add_vertex(
				PackedInt64Array([idx]),
				p_array_vertex[idx],
				PackedVector3Array([p_array_normal[idx]]),
				PackedVector2Array([p_array_tex_uv[idx]])
			)
		start = vertices[0]
		end = vertices[len(vertices)-1]
		
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
		p_bottom_left: Vector3,
		p_top_left: Vector3,
		p_top_right: Vector3,
		p_bottom_right: Vector3,
		
		p_bottom_left_normal := Vector3(),
		p_top_left_normal := Vector3(),
		p_top_right_normal := Vector3(),
		p_bottom_right_normal := Vector3(),
		
		p_bottom_left_uv := Vector2(),
		p_top_left_uv := Vector2(),
		p_top_right_uv := Vector2(),
		p_bottom_right_uv := Vector2(),
	):
		super()
		self.bottom_left = add_vertex(
			[0],
			p_bottom_left,
			[p_bottom_left_normal],
			[p_bottom_left_uv]
		)
		self.top_left = add_vertex(
			[1, 3],
			p_top_left,
			[p_top_left_normal, p_top_left_normal],
			[p_top_left_uv, p_top_left_uv]
		)
		self.top_right = add_vertex(
			[4],
			p_top_right,
			[p_top_right_normal],
			[p_top_right_uv]
		)
		self.bottom_right = add_vertex(
			[2, 5],
			p_bottom_right,
			[p_bottom_right_normal, p_bottom_right_normal],
			[p_bottom_right_uv, p_bottom_right_uv]
		)
		self.apply_all()
		
		
	func as_ATransformableSegment() -> ATransformableSegment:
		return self
		
		
class ATri extends AModifiableSegment:
	var bottom_left: Vertex
	var top: Vertex
	var bottom_right: Vertex
	
	func _init(
		p_bottom_left: Vector3,
		p_top: Vector3,
		p_bottom_right: Vector3,
		
		p_bottom_left_normal := Vector3(),
		p_top_normal := Vector3(),
		p_bottom_right_normal := Vector3(),
		
		p_bottom_left_uv := Vector2(),
		p_top_uv := Vector2(),
		p_bottom_right_uv := Vector2()
	):
		super()
		bottom_left = add_vertex(
			[0],
			p_bottom_left,
			PackedVector3Array([p_bottom_left_normal]),
			PackedVector2Array([p_bottom_left_uv])
		)
		top = add_vertex(
			[1],
			p_top,
			PackedVector3Array([p_top_normal]),
			PackedVector2Array([p_top_uv])
		)
		bottom_right = add_vertex(
			[2],
			p_bottom_right,
			PackedVector3Array([p_bottom_right_normal]),
			PackedVector2Array([p_bottom_right_uv])
		)
		apply_all()
		
# NOTE: AMultiSegment and sub-classes shouldn't alter .untransformed
# directly. Instead, they should get their segments through .get_segments.
# How .get_segments gets their segments is entirely up to the sub-class.
class AMultiSegment extends AModifiableSegment:
	var _array_vertex_index_offset: int = 0
	
	# Override in sub-class.
	func _reset_array_vertex_index_offset() -> void:
		_array_vertex_index_offset = 0
		
	# Override in sub-class.
	func _reset_modifier_cursor() -> void:
		modifier_cursor = 0
	
	# @virtual
	func get_segments() -> Array[AModifiableSegment]:
		return []
	
	func _update_vertices_from_segments() -> void:
		for segment in get_segments():
			for vertex in segment.vertices:
				var updated_indexes := PackedInt64Array()
				for array_vertex_index in vertex.array_vertex_indexes:
					updated_indexes.append(_array_vertex_index_offset + array_vertex_index)
				add_vertex_from_vertex_with_new_indexes(updated_indexes, vertex)
			_array_vertex_index_offset += len(segment.untransformed.get_array_vertex())
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
	
	func _init(p_translation: Vector3):
		translation = p_translation
		
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		p_mutator.translate_vertices(translation)
		
		
class MMultiplyVerticesByVector3 extends Modifier:
	var vector: Vector3
	
	func _init(p_vector: Vector3):
		vector = p_vector
	
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		#mutator.multiply_vertices_by_vector3(self.vector)
		p_mutator.flip_vertices_x()
		
		
class MFlipVerticesX extends MMultiplyVerticesByVector3:
	func _init():
		vector = Vector3(-1, 1, 1)
		
		
class MFlipVerticesYModifier extends MMultiplyVerticesByVector3:
	func _init():
		vector = Vector3(1, -1, 1)
		
		
class MFlipVerticesZModifier extends MMultiplyVerticesByVector3:
	func _init():
		vector = Vector3(1, 1, -1)
		
		
class MFlipTris extends Modifier:
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		p_mutator.flip_tris()
		
		
	# Stretch by the specified amount.
	# The thought model is that the specified amount is the absolute difference
	# between the `end` vertex of the line and some other xyz relative to it.
	# The specified amount will be divided by the number of vertices and the
	# result added to each vertex.
class MStretchVerticesByAmount extends Modifier:
	var stretch_amount: Vector3
	
	func _init(p_stretch_amount: Vector3):
		stretch_amount = p_stretch_amount
		
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		var array_vertex := p_mutator.segment.get_array_vertex()
		var vertex_count := float(len(array_vertex))
		
		if vertex_count < 2.0:
			push_error(\
				"Attempted to stretch mesh with less than 2 vertices. "
				+ "Returning without stretching, as there's nothing to "
				+ "stretch."
			)
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
		p_shear_factor: float,
		p_axis_factors: Vector3
	):
		shear_factor = p_shear_factor
		axis_factors = p_axis_factors
		
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		# TODO: A version of shear_line that makes it so we can operate on
		#  the array directly without the superfluous loop.
		var idx := 0
		# TODO: Normals might have to be adjusted too. Evaluate.
		for vertex in CityGeoFuncs.shear_line(
			p_mutator.segment.get_array_vertex(),
			shear_factor,
			axis_factors
		):
			p_mutator.segment.get_array_vertex()[idx] = vertex
			idx += 1
			
			
class MInvertSurfaceArrays extends Modifier:
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		p_mutator.segment.get_array_vertex().reverse()
		p_mutator.segment.get_array_normal().reverse()
		p_mutator.segment.get_array_tex_uv().reverse()
			
			
class MYUp extends Modifier:
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		var array_vertex := p_mutator.segment.get_array_vertex()
		p_mutator.swap_vertex_components(
			p_mutator.VectorComponentIndex.Y,
			p_mutator.VectorComponentIndex.Z
		)
			
# Flip UVs of a segment of tris.
class MYFlipUVs extends Modifier:
	var CLASS_NAME := "MYFlipUVs"
	
	func modify(p_mutator: IndexChangeTrackingSegmentMutator) -> void:
		var face_count: int
		
		var array_tex_uv := p_mutator.segment.get_array_tex_uv()
		var vertex_count := len(array_tex_uv)
		var incomplete_last_face_vertex_count := vertex_count % 3
		
		if not incomplete_last_face_vertex_count == 0:
			var vertex_count_without_last_face\
			:= vertex_count - incomplete_last_face_vertex_count
			
			face_count = vertex_count_without_last_face / float(3) as int
			
			push_error(
				"Applying the `%s` modifier " % CLASS_NAME
				+ "on a segment that isn't divisible by 3. "
				+ "(%s )" % (3 - incomplete_last_face_vertex_count)
				+  "vertices are missing. "
				+ "The UVs for the last, incomplete tri won't be flipped."
			)
		else:
			face_count = vertex_count / float(3) as int
		
		for i_tri in range(face_count):
			array_tex_uv[3*i_tri].y = 1.0 - array_tex_uv[3*i_tri].y
			array_tex_uv[3*i_tri+1].y = 1.0 - array_tex_uv[3*i_tri+1].y
			array_tex_uv[3*i_tri+2].y = 1.0 - array_tex_uv[3*i_tri+2].y
			
			
###########################################################################
### Segment Library
###########################################################################
			
			
class AMultiQuad extends AMultiSegment:
	var base_quads: Array[AQuad]
	
	func add_quad(p_quad: AQuad):
		base_quads.append(p_quad)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for quad in base_quads:
			segments.append(quad)
		return segments
	
	
class AMultiTri extends AMultiSegment:
	var base_tris: Array[ATri]
	
	func add_tri(p_tri: ATri):
		base_tris.append(p_tri)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for tri in base_tris:
			segments.append(tri)
		return segments
	
	
class AFlushingMultiTri extends AFlushingMultiSegment:
	var _flushable_base_tris: Array[ATri] = []
	
	func add_tri(p_tri: ATri):
		self._flushable_base_tris.append(p_tri)
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for tri in _flushable_base_tris:
			segments.append(tri)
		# This should return an empty array if called again after .apply_all
		# has finished for the first time.
		return segments
		
	func clear_segments() -> void:
		_flushable_base_tris = []
	
	
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
			push_warning(
				"Attempt to set read-only value for `error_message` in "
				+ "`%s` class (or subclass)." % CLASS_NAME
			)
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
		p_class_designation: String,
		p_array1_name := "array1",
		p_array2_name := "array2",
		p_extra_verbose := false
	):
		class_designation = p_class_designation
		array1_name = p_array1_name
		array2_name = p_array2_name
		extra_verbose = p_extra_verbose
		
	func _append_arrays_to_error_message(
		p_error_message: String,
		p_array1: PackedVector3Array,
		p_array2: PackedVector3Array
	) -> String:
		return\
			p_error_message\
			+ " array1: %s. " % p_array1\
			+ "array2: %s." % p_array2
		
	func error_if_not_same_size(
		p_array1: PackedVector3Array,
		p_array2: PackedVector3Array
	) -> String:
		if len(p_array1) == len(p_array1):
			return ""
		var error_details :=\
			" Happened in `%s` (or subclass)." % class_designation\
			+ " %s size: %s." % [array1_name, len(p_array1)]\
			+ " %s size: %s." % [array2_name, len(p_array2)]
		if extra_verbose:
			error_details = _append_arrays_to_error_message(
				error_details,
				p_array1,
				p_array2
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
		p_left_side_vertices: PackedVector3Array,
		p_right_side_vertices: PackedVector3Array
	):
		_side_arrays_error.error_if_not_same_size(
			p_left_side_vertices,
			p_right_side_vertices
		)
		assert(
			_side_arrays_error.is_ok,
			_side_arrays_error.error_message
		)
		left_line = p_left_side_vertices
		right_line = p_right_side_vertices
		
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
			base_quads.append(AQuad.new(
				left_line[number_of_segments_created], # bottom_left
				left_line[number_of_segments_created+1], # top_left
				right_line[number_of_segments_created+1], # top_right
				right_line[number_of_segments_created] # bottom_right
			))
			number_of_segments_created += 1
			
		# Make the triangular tip. If there are only three vertices, this will
		# be the entire segment.
			tip_tri = ATri.new(
				left_line[number_of_segments_created], # left
				left_line[number_of_segments_created+1], # tip
				right_line[number_of_segments_created] # right
			)
			number_of_segments_created += 1
			
			
	func get_segments() -> Array[AModifiableSegment]:
		# TODO: `base_quads.duplicate` isn't working for some reason. When
		# subsequently calling .append, the array stays empty.
		var segments := super()
		for quad in base_quads:
			segments.append(quad)
		segments.append(tip_tri)
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
		p_left_side_vertices: PackedVector3Array,
		p_right_side_vertices: PackedVector3Array
	):
		_side_arrays_error.error_if_not_same_size(
			p_left_side_vertices,
			p_right_side_vertices
		)
		assert(_side_arrays_error.is_ok, _side_arrays_error.error_message)
		
		super()
		
		# TODO: Handle inappropriate number of vertices, e.g. len == 1.
		for idx in range(0, len(p_left_side_vertices) - 1):
			quads.append(AQuad.new(
				p_left_side_vertices[idx], # bottom_left
				p_left_side_vertices[idx+1], # top_left
				p_right_side_vertices[idx+1], # top_right
				p_right_side_vertices[idx] # bottom_right
			))
			
		# TODO: Add support for empty left and right side vertiex arrays.
		bottom_quad = quads[0]
		top_quad = quads[len(quads)-1]
		
		apply_all()
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for quad in self.quads:
			segments.append(quad)
		return segments
		
		
class AFoldedPlane extends AMultiSegment:
	var strips: Array[AHorizontallyFoldedPlane] = []
	
	func _init(
		p_outer_left_outline: ASubdividedLine,
		p_outer_right_outline: ASubdividedLine,
		p_bottom_outline: ASubdividedLine,
		p_top_outline: ASubdividedLine
	):
		super()
		var last_idx := len(p_bottom_outline.get_array_vertex()) - 1
		var left_outline := p_outer_left_outline.copy_as_ASubdividedLine()
		
		for idx in range(0, last_idx):
			var outer_bottom_vertex := p_outer_right_outline.start.transformed
			var inner_bottom_vertex := p_bottom_outline.vertices[idx+1].transformed
			
			var right_outline := p_outer_right_outline.copy_as_ASubdividedLine()
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
				p_top_outline.vertices[idx+1].transformed\
				- right_outline.end.transformed
			))
			right_outline.apply_all()
			
			# NOTE: It might be wise to check whether the right outline and
			# the outer right line are identical when it's the last pass, since
			# they should be. If they aren't, it's an error in this here
			# function. This woud be more of a test/assert level thing, though.
			
			strips.append(AHorizontallyFoldedPlane.new(
				left_outline.get_array_vertex(),
				right_outline.get_array_vertex()
			))
		apply_all()
		
	func get_segments() -> Array[AModifiableSegment]:
		var segments := super()
		for strip in strips:
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
		p_tris: AFlushingMultiTri,
		p_material_indices: PackedInt64Array,
		p_materials: Array[Material] = []
	):
		tris = p_tris
		materials = p_materials
		material_indices = get_inverted_material_indices(p_material_indices)
		
	func get_mesh_instance_3d() -> MeshInstance3D:
		var grouped_surface_arrays := CityGeoFuncs.get_grouped_surfaces_by_material_index(
			material_indices,
			tris.get_arrays()
		)
		var instance_3d := CityGeoFuncs.get_multi_surface_array_mesh_node(
			grouped_surface_arrays
		)
		for i_material in range(len(materials)):
			instance_3d.mesh.surface_set_material(
				i_material,
				materials[i_material]
			)
		
		return instance_3d
		
	func add(p_addee: STris) -> void:
		var vertices := p_addee.tris.get_array_vertex()
		var normals := p_addee.tris.get_array_normal()
		var uvs := p_addee.tris.get_array_tex_uv()
		
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
			tris.add_tri(tri)
		tris.apply_all()
		
		for addee_material in p_addee.materials:
			materials.append(addee_material)
		for addee_material_index in p_addee.material_indices:
			material_indices.append(addee_material_index)
			
	static func get_inverted_material_indices(
		p_material_indices: PackedInt64Array
	):
		var inverted_material_indices := PackedInt64Array()
		var length := len(p_material_indices)
		for i_index in range(length):
			var i_index_inverted := length - i_index - 1
			inverted_material_indices.append(p_material_indices[i_index_inverted])
		return inverted_material_indices
