extends RefCounted
class_name CityMeshLib

# Dependencies:
# - MeshLib

### "Imports": MeshLib
const AMultiSegment := MeshLib.AMultiSegment
const ASubdividedLine := MeshLib.ASubdividedLine
const AFoldedPlane := MeshLib.AFoldedPlane
const MFlipTris := MeshLib.MFlipTris
const MTranslateVertices := MeshLib.MTranslateVertices


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
		p_left_outline: PackedVector3Array,
		p_right_outline: PackedVector3Array,
		# TODO: Will currently only respect 2 vertices, no subdivisions.
		p_bottom_front_outline := PackedVector3Array(),
		# TODO: Since this currently only respects 2 vertices and no
		# subdivisions, this is ineffective right now.
		p_bottom_back_outline := PackedVector3Array(),
	):
		# Convention: Variables defined in this method are prefixed with `l_`,
		# for "local".
		
		assert(len(p_left_outline) >= 3)
		assert(len(p_right_outline) >= 3)
		assert(len(p_left_outline) % 2 != 0)
		
		super()
		
		left_outline = ASubdividedLine.new(p_left_outline)
		right_outline = ASubdividedLine.new(p_right_outline)
		
		var l_p_bottom_front_outline_found_incomplete := false
		if len(p_bottom_front_outline) < 2:
			l_p_bottom_front_outline_found_incomplete = true
			# New array, since len could also be == 1, in which case the
			# appends would cause a mess.
			p_bottom_front_outline = PackedVector3Array()
			p_bottom_front_outline.append(left_outline.start.transformed)
			p_bottom_front_outline.append(right_outline.start.transformed)
		bottom_front_outline = ASubdividedLine.new(p_bottom_front_outline)
		
		if len(p_bottom_back_outline) == len(p_bottom_front_outline):
			bottom_back_outline = ASubdividedLine.new(p_bottom_back_outline)
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
			if l_p_bottom_front_outline_found_incomplete:
				var l_warning_message := "Bottom back outline is not the same "\
					+ "length (%s) " % len(p_bottom_back_outline)\
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
				push_warning(l_warning_message)
				#assert(false, warning_message)
			
			bottom_back_outline = bottom_front_outline.copy_as_ASubdividedLine()
			bottom_back_outline.add_modifier(MTranslateVertices.new(
				left_outline.end.transformed
			))
			bottom_back_outline.apply_all()
			
		assert(left_outline.start.transformed == bottom_front_outline.start.transformed)
		assert(left_outline.end.transformed == bottom_back_outline.start.transformed)
		assert(right_outline.start.transformed == bottom_front_outline.end.transformed)
		assert(right_outline.end.transformed == bottom_back_outline.end.transformed,\
			"right_outline.end: %s, bottom_back_outline.end: %s"\
			% [right_outline.end.transformed, bottom_back_outline.end.transformed]\
		)
		
		outline_ridge_idx = floor(len(left_outline.vertices) / 2.0)
		left_outline_ridge_vertex = left_outline.vertices[outline_ridge_idx].transformed
		right_outline_ridge_vertex = right_outline.vertices[outline_ridge_idx].transformed
		
		left_front_outline = ASubdividedLine.new(
			left_outline.get_array_vertex().slice(0, outline_ridge_idx + 1)
		)
		left_back_outline = ASubdividedLine.new(
			left_outline.get_array_vertex().slice(
				outline_ridge_idx, len(left_outline.vertices)
			)
		)
		right_front_outline = ASubdividedLine.new(
			right_outline.get_array_vertex().slice(0, outline_ridge_idx + 1)
		)
		right_back_outline = ASubdividedLine.new(
			right_outline.get_array_vertex().slice(
				outline_ridge_idx, len(right_outline.vertices)
			)
		)
		
		# TODO: Properly deform the ridge according to the outline shapes.
		#   At the moment we just translate the bottom front outline and stretch
		#   it to get the ridge. This will yield uneven results if the bottom
		#   back outline isn't congruent to it.
		
#		var l_ridge := bottom_front_outline.copy_as_ASubdividedLine()
#		ridge.translate_vertices(left_outline_ridge_vertex)
#		# If we don't apply here, the reference to `ridge.end` below won't
#		# take into account the translation.
#		ridge.apply_all()
#		ridge.stretch_vertices_by_amount(
#			right_outline_ridge_vertex - ridge.end.transformed
#		)
#		ridge.apply_all()
		
		var l_outline_ridge_vertex_difference\
		:= right_outline_ridge_vertex - left_outline_ridge_vertex
		print("outline ridge vertex difference: ", l_outline_ridge_vertex_difference)
		
		var l_ridge_vertex_count := len(bottom_front_outline.vertices)
		var l_ridge_change_rate_per_vertice: float = 1.0 / (l_ridge_vertex_count - 1)
		var l_ridge_vertices := PackedVector3Array()
		for i_ridge_vertex in range(0, l_ridge_vertex_count):
#			print("i_ridge_vertex: %s, change rate: %s, change rate by i_ridge_vertex: %s" % [\
#				i_ridge_vertex, l_ridge_change_rate_per_vertice,\
#				l_ridge_change_rate_per_vertice * i_ridge_vertex\
#			])
			l_ridge_vertices.append(
				# In anticipation of special treatment of the x and z value
				# (for bent ridges), this "exploded view" of the Vector3
				# is left like this for now. If this is found long past the
				# prototyping phase, this can probably be collapsed.
				Vector3(
					left_outline_ridge_vertex.x
					+ l_outline_ridge_vertex_difference.x
					* l_ridge_change_rate_per_vertice
					* i_ridge_vertex,
					left_outline_ridge_vertex.y
					+ l_outline_ridge_vertex_difference.y
					* l_ridge_change_rate_per_vertice
					* i_ridge_vertex,
					left_outline_ridge_vertex.z
					+ l_outline_ridge_vertex_difference.z
					* l_ridge_change_rate_per_vertice
					* i_ridge_vertex
				)
			)
			print(l_ridge_vertices)
		var ridge := ASubdividedLine.new(l_ridge_vertices)
		
		# Debug ridge.
		#var ridge := ASubdividedLine.new(PackedVector3Array([Vector3(0, 0.5, -0.5), Vector3(1, 0.5, -0.5)]))
		
		# TODO: Need an AMultiSegment to produce a folded grid.
		#  Take `create_roof_side` and make one.
		print("===== FRONT ===== ")
		front = AFoldedPlane.new(
			left_front_outline,
			right_front_outline,
			bottom_front_outline,
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
			bottom_back_outline,
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
		back.add_modifier(MFlipTris.new())
		back.apply_all()
		apply_all()
		
		# Bug: There is a small errant polygon on the inside, per plane.
		# CONTINUE: Debug AFoldedPlane next. The problem is probably there.
		var vector_arrays := {
			# Contains Vector3(0, 0.5, -0.5)
			"left_outline": left_outline.get_array_vertex(),
			"left_front_outline": left_front_outline.get_array_vertex(),
			"left_back_outline": left_back_outline.get_array_vertex(),
			"ridge_vertices": ridge.get_array_vertex(),
			"front": front.get_array_vertex(),
			"back": back.get_array_vertex(),
			
			# Does NOT contain it.
			"right_outline": right_outline.get_array_vertex(),
			"bottom_front_outline": bottom_front_outline.get_array_vertex(),
			"bottom_back_outline": bottom_back_outline.get_array_vertex(),
			"right_front_outline": right_front_outline.get_array_vertex(),
			"right_back_outline": right_back_outline.get_array_vertex(),
			"ridge": ridge.get_array_vertex(),
		}
		for key in vector_arrays:
			var vertices: PackedVector3Array = vector_arrays[key]
			if Vector3(0, 0.5, -0.5) in vertices:
				print("found in:", key)
			else:
				print("not found in:", key)
		
	func get_segments() -> Array[AVertexTrackingSegment]:
		#return [front]
		return [front, back]
