extends RefCounted
class_name MeshLib

# Dependencies:
# - CityGeoFuncs


# Base class for ArrayMesh array classes for arrays of any number of array_vertex.
# Has common elements such as the arrays and transforms.
class ASegment:
	var _arrays: Array = []
	var _array_vertex := PackedVector3Array():
		set(value):
			_arrays[ArrayMesh.ARRAY_VERTEX] = value
		get:
			return _arrays[ArrayMesh.ARRAY_VERTEX]
			
			# This produces weird results, with `.resize` not working
			# and nulled Vector3s getting returned even when they shouldn't
			# be nulled.
			#return arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
		
	func _init(
		arrays: Array = [],
		array_vertex: PackedVector3Array = PackedVector3Array()
	):
		_init_arrays(arrays, array_vertex)
		self._array_vertex = array_vertex
		
	func _init_arrays(
		arrays: Array = [],
		_array_vertex: PackedVector3Array = PackedVector3Array()
	):
		self._arrays = arrays
		self._arrays.resize(ArrayMesh.ARRAY_MAX)
		
		if len(_array_vertex) > 0 or arrays[ArrayMesh.ARRAY_VERTEX] == null:
			self._arrays[ArrayMesh.ARRAY_VERTEX] = _array_vertex
		
	func get_array_vertex() -> PackedVector3Array:
		return _array_vertex
		
	func copy_inverted_array_vertex() -> PackedVector3Array:
		var inverted_array_vertex_copy := PackedVector3Array()
		inverted_array_vertex_copy.resize(len(_array_vertex))
		for idx in range(0, len(_array_vertex)):
			inverted_array_vertex_copy[idx] = _array_vertex[len(_array_vertex) - idx - 1]
		return inverted_array_vertex_copy
		
		
# Proxies a `ASegment` for added transform features.
# Our `_array_vertex` array is transformed according to `transform` whenever
# it's accessed, unless `apply_transform_on_access` is set to `false`. In that
#case, `apply_transform` has to be explicitely called for the transform to be
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
		# `resize` doesn't work for some reason when using it on `._array_vertex`.
		_array_vertex.resize(len(untransformed._array_vertex))
		
	# Applies `.transform` to all arrays.
	func apply_transform() -> void:
		ensure_equal_array_size()
		for idx in range(0, len(untransformed._array_vertex)):
			var basis_changed: Vector3 = transform.basis * untransformed._array_vertex[idx]
			_array_vertex[idx] = transform.origin + basis_changed
		apply_offset()
		
		# Experiment: Trying to rotate in place.
#		for idx in range (0, len(_array_vertex)):
#			var basis_changed: Vector3 = offset.basis * _array_vertex[idx]
#			_array_vertex[idx] = offset.origin + basis_changed
		
	# Integrate this directly into offset? Prepend it with an underscore?
	# Reason for it being a distinct method: Prototyping clarity.
	# However, it might also be confusing if there is an "offset", but no
	# apply method for it. The offset is mostly a feature of "transform",
	# though, but broken out into its own thing so the transform can be
	# changed without having to mess with any offset that might have been
	# previously applied to it.
	func apply_offset() -> void:
		ensure_equal_array_size()
		for idx in range (0, len(_array_vertex)):
			var basis_changed: Vector3 = offset.basis * _array_vertex[idx]
			_array_vertex[idx] = offset.origin + basis_changed
		
	func apply_all() -> void:
		apply_transform()
		
	func multiply_vertices_by_vector3(vector: Vector3):
		for idx in range(0, len(untransformed._array_vertex) - 1):
			untransformed._array_vertex[idx] = untransformed._array_vertex[idx] * vector
		
	func flip_vertices_x() -> void:
		multiply_vertices_by_vector3(Vector3(-1, 1, 1))
		
	func flip_vertices_y() -> void:
		multiply_vertices_by_vector3(Vector3(1, -1, 1))
		
	func flip_vertices_z() -> void:
		multiply_vertices_by_vector3(Vector3(1, 1, -1))
		
	func translate_vertices(vector: Vector3) -> void:
		for idx in range(0, len(untransformed._array_vertex)):
			untransformed._array_vertex[idx] = untransformed._array_vertex[idx] + vector
			
			
class Vertex:
	var transformed_segment: ATransformableSegment
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
	):
		assert(len(array_vertex_indexes) > 0,\
			"The array_vertex_indexes array must contain at least one index.")
		
		self.array_vertex_indexes = array_vertex_indexes
		self.vertex_array_primary_index = array_vertex_indexes[0]
		self.transformed_segment = transformed
		self.untransformed_segment = untransformed
		
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
		initial_value: Vector3 = Vector3()
	) -> Vertex:
		var vertex := Vertex.new(
			initial_value,
			self,
			untransformed,
			array_vertex_indexes
		)
		vertices.append(vertex)
		
		# Make sure the untransformed vertex array is at least as long as
		# the largest index of our vertex.
		var highest_index := 0
		for index in vertex.array_vertex_indexes:
			if index > highest_index:
				highest_index = index
			
		if len(untransformed._array_vertex) <= highest_index:
			untransformed._array_vertex.resize(highest_index + 1)
		
		# Set the vertex positions of all the indexes of this vertex in the
		# untransformed vertex array.
		#TODO: This should probably be refactored into `Vertex`.
		for index in vertex.array_vertex_indexes:
			untransformed._array_vertex[index] = initial_value
		
		return vertex
		
	func flip_tris() -> void:
		var vertex_objects_by_array_vertex_idx := Dictionary()
		
		var new_array_vertex_indexes := PackedInt64Array()
		new_array_vertex_indexes.resize(len(untransformed._array_vertex))
		
		# Recording the original state to compare to after we're done for
		# debugging.
		var debug_vertices_originals_untransformed := PackedVector3Array()
		var debug_vertices_originals_indexes := []
		for vertex in vertices:
			debug_vertices_originals_untransformed.append(Vector3(
				vertex.untransformed.x,
				vertex.untransformed.y,
				vertex.untransformed.z
			))
			
			var indexes := PackedInt64Array()
			for index in vertex.array_vertex_indexes:
				indexes.append(index)
			debug_vertices_originals_indexes.append(indexes)
		
		
		for vertex in vertices:
			for idx in vertex.array_vertex_indexes:
				vertex_objects_by_array_vertex_idx[idx] = vertex
			
				
		for idx in range(0, len(_array_vertex), 3):
			# The new array vertex indexes are getting flipped as intended.

			new_array_vertex_indexes[idx] = idx
#
#			# Purposfully broken for debugging:
			#new_array_vertex_indexes[idx+2] = idx
#			# Unbroken:
			new_array_vertex_indexes[idx+1] = idx+2
#
			new_array_vertex_indexes[idx+2] = idx+1

			var tmp_idx_plus_1_value := untransformed._array_vertex[idx+1]
			untransformed._array_vertex[idx+1] = untransformed._array_vertex[idx+2]
			untransformed._array_vertex[idx+2] = tmp_idx_plus_1_value


			# Bug: Testing whether this makes the vertices objects have
			# unchanged references. It does.
#			new_array_vertex_indexes[idx] = idx
#			new_array_vertex_indexes[idx+1] = idx+1
#			new_array_vertex_indexes[idx+2] = idx+2
#			var tmp_idx_plus_1_value := untransformed._array_vertex[idx+2]
#			untransformed._array_vertex[idx+1] = untransformed._array_vertex[idx+1]
#			untransformed._array_vertex[idx+2] = tmp_idx_plus_1_value
			
			
		var vertex_idx := 0
		for vertex in vertices:
			var old_index_idx := 0
			for old_index in vertex.array_vertex_indexes:
				vertex.array_vertex_indexes[old_index_idx] = new_array_vertex_indexes[old_index]
				vertex.vertex_array_primary_index = vertex.array_vertex_indexes[0]
				old_index_idx += 1
			vertex_idx += 1
				
		## Commented out to purposefully break `vertices` mapping for debugging.
		# This doesn't seem to do anything according to the originals comparison.
#			for array_vertex_indexes_idx in range(0, len(vertex.array_vertex_indexes)):
#				for new_array_vertex_indexes_idx in range(0, len(new_array_vertex_indexes)):
#					var old_idx := vertex.array_vertex_indexes[array_vertex_indexes_idx]
#					var new_idx := new_array_vertex_indexes[new_array_vertex_indexes_idx]
#					if old_idx == new_array_vertex_indexes_idx:
#						print("old idx: ", old_idx, " new array vertex indexes idx: ", new_array_vertex_indexes_idx)
#						vertex.array_vertex_indexes[array_vertex_indexes_idx] = new_array_vertex_indexes[new_array_vertex_indexes_idx]
			
		# Bug: The flip is correct here.
		print(new_array_vertex_indexes)
		# Bug: It seems [1, 3] stays the same, whilst [2, 5] is correctly
		# becoming [1, 4]. The "plus" part doesn't seem to be happening.
		for idx in range(0, len(vertices)):
			var same_or_not := "Same: "
			if debug_vertices_originals_untransformed[idx] != vertices[idx].untransformed:
				same_or_not = "Not same: "
			print(
				same_or_not, debug_vertices_originals_untransformed[idx],
				" After: ", vertices[idx].untransformed,
				" Orig. indexes: ", debug_vertices_originals_indexes[idx],
				" New indexes: ", vertices[idx].array_vertex_indexes
			)
			#print("Not the same. Before: ", debug_vertices_originals_untransformed[idx], " After: ", vertices[idx].untransformed)
			
#			if vertex_objects_by_array_vertex_idx.has(idx+1):
#				var vertex: Vertex = vertex_objects_by_array_vertex_idx[idx+1]
#
#				var stale_idx_index := 0
#				for stale_idx in vertex.array_vertex_indexes:
#					if stale_idx == idx+1:
#						vertex.array_vertex_indexes[stale_idx_index] = idx+1
#						vertex.vertex_array_primary_index = vertex.array_vertex_indexes[0]
#					stale_idx_index += 1
#
#			if vertex_objects_by_array_vertex_idx.has(idx+2):
#				var vertex: Vertex = vertex_objects_by_array_vertex_idx[idx+2]
#
#				var stale_idx_index := 0
#				for stale_idx in vertex.array_vertex_indexes:
#					if stale_idx == idx+2:
#						vertex.array_vertex_indexes[stale_idx_index] = idx-1
#						vertex.vertex_array_primary_index = vertex.array_vertex_indexes[0]
#					stale_idx_index += 1
						
						
class APoint extends AVertexTrackingSegment:
	var vertex: Vertex
	
	func _init(
		vertex: Vector3
	):
		self.vertex = add_vertex([0], vertex)
		
# Idea:
# One way to have AVertexTrackingSegments with edges and faces is to create further
# subclasses of it that feature these things, which will then be parent classes
# to AQuad and so on.
		
		
class ALine extends AVertexTrackingSegment:
	var start: Vertex
	var end: Vertex
	
	func _init(
		start: Vector3,
		end: Vector3,
		# Intended for subclassing use. This enables subclasses to start
		# initializing their geometry on a clean object; `start` and `end` will
		# be Nil.
		_no_vertex_init := false
	):
		super()
		if not _no_vertex_init:
			self.start = add_vertex([0], start)
			self.end = add_vertex([1], end)
			apply_all()
		
		
	func shear_vertices(
		shear_factor: float,
		axis_factors: Vector3
	) -> void:
		# TODO: A version of shear_line that makes it so we can operate on
		#  the array directly without the superfluous loop.
		var idx := 0
		for vertex in CityGeoFuncs.shear_line(
			untransformed._array_vertex,
			shear_factor,
			axis_factors
		):
			untransformed._array_vertex[idx] = vertex
			idx += 1
		
	# Stretch by the specified amount.
	# The thought model is that the specified amount is the absolute difference
	# between the `end` vertex of the line and some other xyz relative to it.
	# The specified amount will be divided by the number of vertices and the
	# result added to each vertice.
	func stretch_vertices_by_amount(
		stretch_amount: Vector3
	) -> void:
		var vertex_count := float(len(untransformed._array_vertex))
		
		if vertex_count < 2:
			push_error(\
				"Attempted to stretch line with less than 2 vertices. "
				+ "Returning without stretching, as there's nothing to stretch.")
			return
		assert(vertex_count >= 2.0)
		
		var stretch_amount_per_vertex := stretch_amount / (vertex_count - 1)
		
		for idx in range(1, len(untransformed._array_vertex)):
			var vertex = untransformed._array_vertex[idx]
			untransformed._array_vertex[idx] = vertex + stretch_amount_per_vertex
			idx += 1
		
		
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
		# subdivisions := 0
	):
		assert(len(array_vertex) > 1)
		
		super(Vector3(), Vector3(), true)
		
		for idx in range(0, len(array_vertex)):
			add_vertex([idx], array_vertex[idx])
		self.start = vertices[0]
		self.end = vertices[len(vertices)-1]
		
		apply_all()
		
	func copy_as_ASubdividedLine() -> ASubdividedLine:
		return ASubdividedLine.new(
			get_array_vertex().duplicate()
		)
		
		
class AQuad extends AVertexTrackingSegment:
	var bottom_left: Vertex
	var top_left: Vertex
	var top_right: Vertex
	var bottom_right: Vertex
	
	func _init(
		bottom_left: Vector3,
		top_left: Vector3,
		top_right: Vector3,
		bottom_right: Vector3,
	):
		super()
		
		# Working:
		self.bottom_left = add_vertex([0], bottom_left)
		self.top_left = add_vertex([1, 3], top_left)
		self.top_right = add_vertex([4], top_right)
		self.bottom_right = add_vertex([2, 5], bottom_right)
		
		# Flipping experiment:
#		self.bottom_left = add_vertex([0], bottom_left)
#		self.top_left = add_vertex([2, 3], top_left)
#		self.top_right = acdd_vertex([5], top_right)
#		self.bottom_right = add_vertex([1, 4], bottom_right)
		
		self.apply_all()

		
	func as_ATransformableSegment() -> ATransformableSegment:
		return self
		
		
class ATri extends AVertexTrackingSegment:
	var bottom_left: Vertex
	var top: Vertex
	var bottom_right: Vertex
	
	func _init(
		bottom_left: Vector3,
		top: Vector3,
		bottom_right: Vector3,
	):
		super()
		self.bottom_left = add_vertex([0], bottom_left)
		self.top = add_vertex([1], top)
		self.bottom_right = add_vertex([2], bottom_right)
		self.apply_all()
		
		
# Adding this as modifier to a modifier system might also be an option.
class AMultiSegment extends AVertexTrackingSegment:
	# @virtual
	func get_segments() -> Array[AVertexTrackingSegment]:
		return []
	
	func _update_vertices_from_segments() -> void:
		var array_vertex_index_offset: int = 0
		for segment in get_segments():
			for vertex in segment.vertices:
				var updated_indexes := PackedInt64Array()
				for array_vertex_index in vertex.array_vertex_indexes:
					updated_indexes.append(array_vertex_index_offset + array_vertex_index)
				add_vertex(updated_indexes, vertex.untransformed)
			array_vertex_index_offset += len(segment.untransformed.get_array_vertex())
		return
		
	func apply_segments() -> void:
		_update_vertices_from_segments()
	
	func apply_all() -> void:
		apply_segments()
		super()
	
	# @virtual
	func as_AVertexTrackingSegment(apply_all := false) -> AVertexTrackingSegment:
		# TODO: Proper implementation. :p
		apply_segments()
		return self
	
	
class AMultiQuad extends AMultiSegment:
	var base_quads: Array[AQuad]
	
	func add_quad(quad: AQuad):
		base_quads.append(quad)
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		var segments: Array[AVertexTrackingSegment] = []
		for quad in base_quads:
			segments.append(quad)
		return segments
	
	
class AMultiTri extends AMultiSegment:
	var base_tris: Array[ATri]
	
	func add_tri(tri: ATri):
		base_tris.append(tri)
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		var segments: Array[AVertexTrackingSegment] = []
		for tri in base_tris:
			segments.append(tri)
		return segments
	
	
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
			# Ready-only.
			push_warning("Attempt to set read-only value for `error_message` in"
				+ " `%s` class (or subclass)." % CLASS_NAME)
		get:
			return " -- ".join(error_messages)
		
	var extra_verbose := false
	var arrays_set := false
	var is_ok: bool:
		set(value):
			# Ready-only.
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
			" Happened in `%s` (or subclass)." % class_designation\
			+ " %s size: %s." % [array1_name, len(array1)]\
			+ " %s size: %s." % [array2_name, len(array2)]
		if extra_verbose:
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
		"AHorizontallyFoldedTriangularPlane", # Class name.
		"left side vertex array",
		"right side vertex array"
	)
	
	var left_line: PackedVector3Array
	var right_line: PackedVector3Array
	var base_quads: Array[AQuad]
	var tip_tri: ATri
	
	# TODO: Add support for empty left and right side vertice arrays.
	func _init(
		left_side_vertices: PackedVector3Array,
		right_side_vertices: PackedVector3Array
	):
#		_side_arrays_error.error_if_not_same_size(
#			left_side_vertices,
#			right_side_vertices
#		)
#		assert(_side_arrays_error.is_ok, _side_arrays_error.error_message)
		left_line = left_side_vertices
		right_line = right_side_vertices
		
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
		# can construct from the "bottom left" vertice up.
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
			
	func get_segments() -> Array[AVertexTrackingSegment]:
		# TODO: `base_quads.duplicate` isn't working for some reason. When
		# subsequently calling .append, the array stays empty.
		var segments: Array[AVertexTrackingSegment] = []
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
		left_side_vertices: PackedVector3Array,
		right_side_vertices: PackedVector3Array
	):
		_side_arrays_error.error_if_not_same_size(
			left_side_vertices,
			right_side_vertices
		)
		assert(_side_arrays_error.is_ok, _side_arrays_error.error_message)
		
		super()
		# TODO: Handle inappropriate number of vertices, e.g. len == 1.
		for idx in range(0, len(left_side_vertices) - 1):
			quads.append(AQuad.new(
				left_side_vertices[idx], # bottom_left
				left_side_vertices[idx+1], # top_left
				right_side_vertices[idx+1], # top_right
				right_side_vertices[idx] # bottom_right
			))
			
		# TODO: Add support for empty left and right side vertice arrays.
		self.bottom_quad = quads[0]
		self.top_quad = quads[len(quads)-1]
		
		apply_all()
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		var segments: Array[AVertexTrackingSegment] = []
		for quad in quads:
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
		var left_outline := outer_left_outline.copy_as_ASubdividedLine()
		
		var last_idx := len(bottom_outline.get_array_vertex()) - 1
		for idx in range(0, last_idx):
			#print("AFoldedPlane translation, idx: ", idx)
			
			var outer_bottom_vertex := outer_right_outline.start.transformed
			var inner_bottom_vertex := bottom_outline.vertices[idx+1].transformed
			
			var right_outline := outer_right_outline.copy_as_ASubdividedLine()
			var right_outline_translation: Vector3 =\
				# For the back plane we'll have to transform this before
				# passing it here, so the start is at the bottom... but that
				# might mess with UV Maps later... perhaps?
				# That might not be an issue, though, if the texture is
				# supposed to be mapped from the bottom left for each side.
				(outer_bottom_vertex - inner_bottom_vertex) * -1
			right_outline.translate_vertices(
				right_outline_translation
			)
			right_outline.apply_all()
			# Bug: This causes the (wrong) stretch to be partially downwards.
			var stretch_amount :=\
				top_outline.vertices[idx+1].transformed\
				- right_outline.end.transformed
			right_outline.stretch_vertices_by_amount(
				stretch_amount
			)
			right_outline.apply_all()
			
			
			# NOTE: It might be wise to check whether the right outline and
			# the outer right line are identical when it's the last pass, since
			# they should be. If they aren't, it's an error in this here function.
			# This woud be more of a test/assert level thing, though.
			
			strips.append(AHorizontallyFoldedPlane.new(
				left_outline.get_array_vertex(),
				right_outline.get_array_vertex()
			))
			
			left_outline = right_outline.copy_as_ASubdividedLine()
			
		apply_all()
			
#	func get_segments() -> Array[ATransformableSegment]:
#		return strips as Array[ATransformableSegment]
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		var segments: Array[AVertexTrackingSegment] = []
		for strip in strips:
			segments.append(strip)
		return segments
