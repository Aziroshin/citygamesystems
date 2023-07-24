extends RefCounted
class_name CityMeshLib

# Dependencies:
# - MeshLib


### "Imports": MeshLib
const AMultiSegment := MeshLib.AMultiSegment
const ASubdividedLine := MeshLib.ASubdividedLine
const AFoldedPlane := MeshLib.AFoldedPlane


class ATwoSidedRoof extends AMultiSegment:
	var front: AFoldedPlane
	var back: AFoldedPlane
	var outline_ridge_idx: int
	
	var left_outline: ASubdividedLine
	var left_outline_ridge_vertex: Vector3
	var left_front_outline: ASubdividedLine
	var left_back_outline: ASubdividedLine
	
	var right_outline: ASubdividedLine
	var right_outline_ridge_vertex: Vector3
	var right_front_outline: ASubdividedLine
	var right_back_outline: ASubdividedLine
	
	var bottom_front_outline: ASubdividedLine
	var bottom_back_outline: ASubdividedLine
	
	var ridge: ASubdividedLine
	
	func _init(
		left_outline: PackedVector3Array,
		right_outline: PackedVector3Array,
		# TODO: Will currently only respect 2 vertices, no subdivisions.
		bottom_front_outline := PackedVector3Array(),
		# TODO: Since this currently only respects 2 vertices and no
		# subdivisions, this is ineffective right now.
		bottom_back_outline := PackedVector3Array(),
	):
		assert(len(left_outline) >= 3)
		assert(len(right_outline) >= 3)
		assert(len(left_outline) % 2 != 0)
		
		super()
		
		self.left_outline = ASubdividedLine.new(left_outline)
		self.right_outline = ASubdividedLine.new(right_outline)
		
		var bottom_front_outline_found_incomplete := false
		if len(bottom_front_outline) < 2:
			bottom_front_outline_found_incomplete = true
			# New array, since len could also be == 1, in which case the
			# appends would cause a mess.
			bottom_front_outline = PackedVector3Array()
			bottom_front_outline.append(self.left_outline.start.transformed)
			bottom_front_outline.append(self.right_outline.start.transformed)
		self.bottom_front_outline = ASubdividedLine.new(bottom_front_outline)
		
		if len(bottom_back_outline) == len(bottom_front_outline):
			self.bottom_back_outline = ASubdividedLine.new(bottom_back_outline)
		else:
			# This assumes the bottom back outline hasn't been specified, which
			# indicates it's supposed to have the same shape as the front.
			#
			# TODO: It could also mean the bottom front outline was specified
			#   with an empty array, whilst the bottom back outline has been
			#   specified with some values (e.g. a proper outline). This case
			#   is currently not respected here. Perhaps it could be checked for
			#   and the bottom front outline could be initialized from the
			#   bottom back outline instead in that case.
			#   CAVEAT: Too much magic like that might make the behaviour of the
			#     class confusing to intuit.
			if bottom_front_outline_found_incomplete:
				var warning_message := "Bottom back outline is not the same "\
					+ "length (%s) " % len(bottom_back_outline)\
					+ "as the bottom front outline "\
					+ "(%s), " % len(bottom_front_outline)\
					+ "but the latter was found to have too few vertices "\
					+ "before inferring a default for it. This probably means "\
					+ "that a bottom back outline has been specified, but an "\
					+ "empty array has been passed for the bottom front "\
					+ "outline array, which, in the current implementation, "\
					+ "construes unorthodox use of this class, indicating a "\
					+ "bug at the call site. Stack (if there's no debugger "\
					+ "connection this will be empty): "\
					+ " -- ".join(get_stack())
				push_warning(warning_message)
				#assert(false, warning_message)
			
			self.bottom_back_outline = self.bottom_front_outline.copy_as_ASubdividedLine()
			self.bottom_back_outline.translate_vertices(self.left_outline.end.transformed)
			self.bottom_back_outline.apply_all()
			
		assert(self.left_outline.start.transformed == self.bottom_front_outline.start.transformed)
		assert(self.left_outline.end.transformed == self.bottom_back_outline.start.transformed)
		assert(self.right_outline.start.transformed == self.bottom_front_outline.end.transformed)
		assert(self.right_outline.end.transformed == self.bottom_back_outline.end.transformed,\
			"right_outline.end: %s, bottom_back_outline.end: %s"\
			% [self.right_outline.end.transformed, self.bottom_back_outline.end.transformed]\
		)
		
		outline_ridge_idx = floor(len(self.left_outline.vertices) / 2.0)
		left_outline_ridge_vertex = self.left_outline.vertices[outline_ridge_idx].transformed
		right_outline_ridge_vertex = self.right_outline.vertices[outline_ridge_idx].transformed
		
		left_front_outline = ASubdividedLine.new(
			self.left_outline.get_array_vertex().slice(0, outline_ridge_idx + 1)
		)
		left_back_outline = ASubdividedLine.new(
			self.left_outline.get_array_vertex().slice(
				outline_ridge_idx, len(self.left_outline.vertices)
			)
		)
		right_front_outline = ASubdividedLine.new(
			self.right_outline.get_array_vertex().slice(0, outline_ridge_idx + 1)
		)
		right_back_outline = ASubdividedLine.new(
			self.right_outline.get_array_vertex().slice(
				outline_ridge_idx, len(self.right_outline.vertices)
			)
		)
		
		# TODO: Properly deform the ridge according to the outline shapes.
		#   At the moment we just translate the bottom front outline and stretch
		#   it to get the ridge. This will yield uneven results if the bottom
		#   back outline isn't congruent to it.
		
#		var ridge := self.bottom_front_outline.copy_as_ASubdividedLine()
#		ridge.translate_vertices(left_outline_ridge_vertex)
#		# If we don't apply here, the reference to `ridge.end` below won't
#		# take into account the translation.
#		ridge.apply_all()
#		ridge.stretch_vertices_by_amount(
#			right_outline_ridge_vertex - ridge.end.transformed
#		)
#		ridge.apply_all()
		
		var outline_ridge_vertex_difference := right_outline_ridge_vertex - left_outline_ridge_vertex
		print("outline ridge vertex difference: ", outline_ridge_vertex_difference)
		
		var ridge_vertice_count := len(self.bottom_front_outline.vertices)
		var ridge_change_rate_per_vertice: float = 1.0 / (ridge_vertice_count - 1)
		var ridge_vertices := PackedVector3Array()
		for idx in range(0, ridge_vertice_count):
			#print("idx: %s, change rate: %s, change rate by idx: %s" % [idx, ridge_change_rate_per_vertice, ridge_change_rate_per_vertice * idx])
			ridge_vertices.append(
				# In anticipation of special treatment of the x and z value
				# (for bent ridges), this "exploded view" of the Vector3
				# is left like this for now. If this is found long past the
				# prototyping phase, this can probably be collapsed.
				Vector3(
					left_outline_ridge_vertex.x + outline_ridge_vertex_difference.x * ridge_change_rate_per_vertice * idx,
					left_outline_ridge_vertex.y + outline_ridge_vertex_difference.y * ridge_change_rate_per_vertice * idx,
					left_outline_ridge_vertex.z + outline_ridge_vertex_difference.z * ridge_change_rate_per_vertice * idx
				)
			)
		var ridge := ASubdividedLine.new(ridge_vertices)
		
		# Debug ridge.
		#var ridge := ASubdividedLine.new(PackedVector3Array([Vector3(0, 0.5, -0.5), Vector3(1, 0.5, -0.5)]))
		
		# TODO: Need an AMultiSegment to produce a folded grid.
		#  Take `create_roof_side` and make one.
		print("===== FRONT ===== ")
		front = AFoldedPlane.new(
			left_front_outline,
			right_front_outline,
			self.bottom_front_outline,
			ridge
		)
		print("===== BACK =====")
		back = AFoldedPlane.new(
			# We invert because the line has to `start` at the bottom outline
			# and `end` at the ridge, but the left and right back outlines do
			# the opposite, because of how they're sliced off from the original
			# full outline.
			ASubdividedLine.new(left_back_outline.copy_inverted_array_vertex()),
			ASubdividedLine.new(right_back_outline.copy_inverted_array_vertex()),
			self.bottom_back_outline,
			ridge
		)
		
		# back.untransformed._array_vertex = back.untransformed.copy_tri_flipped_array_vertex()
		
		
		# Debug - this is still warped. o,O
#		back = AFoldedPlane.new(
##			ASubdividedLine.new(PackedVector3Array([Vector3(1, 0.5, -0.5), Vector3(1, 0, -1)])),
##			ASubdividedLine.new(PackedVector3Array([Vector3(0, 0.5, -0.5), Vector3(0, 0, -1)])),
#			ASubdividedLine.new(PackedVector3Array([Vector3(0, 0.5, -0.5), Vector3(0, 0, -1)])),
#			ASubdividedLine.new(PackedVector3Array([Vector3(1, 0.5, -0.5), Vector3(1, 0, -1)])),
#			ASubdividedLine.new(PackedVector3Array([Vector3(0, 0, -1), Vector3(1, 0, -1)])),
#			ASubdividedLine.new(PackedVector3Array([Vector3(0, 0.5, -0.5), Vector3(1, 0.5, -0.5)]))
#		)
		
		apply_all()
		back.flip_tris()
		apply_all()
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		#return [front, back]
		return [front, back]
