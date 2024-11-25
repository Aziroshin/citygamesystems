extends RefCounted
class_name CityBuilder


# "Imports": PositionerLib
const TaggablePositioner := PositionerLib.TaggablePositioner


enum HouseSideKinds {
	FREE,
	ADJACENT,
	BERLIN_CORNER,
	# MAIN #  Maybe useful for special houses.
}


enum HouseSideExposedness {
	BUSY,
	PRIVATE
}


# Archived.
# Code-doodle for builder-pattern house features. Also, the idea was to have
# an object that can be passed on to generators without having to mess too much
# with the limitations of the type hint system in the absence of generics. One
# big object with all the features would do that, but it'd also make things
# messy if other projects need to add their own features for their generators.
# Furthermore, it doesn't preserve the respective exclusiveness of "kind" and
# "exposedness" items, and adding the enums would greatly reduce the readability
# of the builder pattern approach.
class HouseSideFeatures:
	class Kind:
		var delegator: HouseSideFeatures
		var free = false
		var adjacent = false
		var berlin_corner = false
		
		func _init(p_delegator: HouseSideFeatures):
			delegator = p_delegator
		
		func set_free(p_value: bool) -> HouseSideFeatures:
			free = p_value
			return delegator
			
		func set_adjacent(p_value: bool) -> HouseSideFeatures:
			adjacent = p_value
			return delegator
	
	
	class Exposedness:
		var delegator: HouseSideFeatures
		var busy = false
		var private = false
		
		func _init(p_delegator: HouseSideFeatures):
			delegator = p_delegator
		
		func set_busy(p_value: bool) -> HouseSideFeatures:
			busy = p_value
			return delegator
			
	var kind: Kind
	var exposedness: Exposedness
	
	func _init():
		kind = Kind.new(self)
		exposedness = Exposedness.new(self)


# Note: The points of a house side describe a 3D line, whereas `y` will need
# special consideration in generators regarding ground-level and sous-de-terre
# facade bits.
class HouseSide:
	var points: PackedVector3Array
	var start: Vector3:
		get:
			return points[0]
	var end: Vector3:
		get:
			return points[len(points)-1]
	var start_to_end: Vector3:
		get:
			return end - start
	
	func _init(
		p_points: PackedVector3Array,
		_p_kind: HouseSideKinds,
		_p_exposedness: HouseSideExposedness
	):
		assert(len(p_points) >= 2)


# TODO: Holds all `HouseSide` objects for a house and includes sanity
#  checks to make sure the sides fit in a way it makes sense for a house.
#  Might also include arrays for various outlines across all the sides, e.g.
#  the outline of the foundation or the top outline of all the sides put
#  together, or roof outlines, etc.
#  Might also include convenience methods or getters, e.g. whether the number
#  of sides is even or somesuch.
class HouseFrame:
	var sides: Array[HouseSide]
	
	func _init(_p_sides: Array[HouseSide]):
		pass
		# Assert/test/push_error whether the set of points from all the
		# house sides form a loop (good) or not (bad).


# Idea-stub & basic "interface" for lowest-common-denominator type erasure
# for "Building" classes. Time will tell what functionality it'll have, if
# any.
class Building:
	pass


class SimpleRowHouse extends Building:
	var frame: HouseFrame
	
	func _init(
		_p_frame: HouseFrame
	):
		pass


class LayoutDistalOutline extends Resource:
	var layout: Layout
	var offset_magnitude: float
	var offset_direction: Vector3
	
	func _init(
		p_layout: Layout,
		p_offset_magnitude := 1.0,
		p_offset_direction := Vector3.UP
	):
		layout = p_layout
		offset_magnitude = p_offset_magnitude
		offset_direction = p_offset_direction
		
	func get_offset() -> Vector3:
		return offset_direction * offset_magnitude
		
	func calculate_distal_points():
		pass
		
	func get_points() -> PackedVector3Array:
		var points := PackedVector3Array()
		var distal_offset := get_offset()
		for proximal_point in layout.outline_points:
			points.append(proximal_point + distal_offset)
		return points


## A 3D-space bounded by a proximal and a distal set of points, with two
## resolutions: Corner points and outline points, whereas corner points are
## among the outline points.
##
## In your typical city game, proximal would probably refer to the ground, and
## distal to the upper bounding curve. A game with buildings hanging from a
## cavern ceiling or branches, with code that generates buildings from top to
## bottom, this could be different, however.
##
## Corner points are useful to denote the edges of straight facades, whereas
## the curve points may lend themselves to fancier facade designs as well as
## other kinds of plot layouts, such as gardens, plazas or street filler parts,
## whilst still using the corner information to determine, for example, which
## sides are the "busy" type.
##
## `outline_points`, `corner_indexes` and `corner_points` need to be managed
## together - if you change the outline points, you'll have to change the
## indexes accordingly as well, then call `refresh_corner_points`.
##
class Layout extends Node3D:
	var outline_points: PackedVector3Array
	var corner_indexes: PackedInt64Array
	var distal_outline: LayoutDistalOutline
	var corner_points: PackedVector3Array
	
	func _init(
		p_outline_points := PackedVector3Array(),
		p_corner_indexes := PackedInt64Array(),
		p_distal_outline_offset_magnitude := 1.0,
		p_distal_outline_offset_direction := Vector3.UP
	):
		assert(len(p_corner_indexes) <= len(p_outline_points))
		assert(len(p_corner_indexes) >= 3)
		
		outline_points = p_outline_points
		corner_indexes = p_corner_indexes
		distal_outline = LayoutDistalOutline.new(
			self,
			p_distal_outline_offset_magnitude,
			p_distal_outline_offset_direction
		)
		
		refresh_corner_points()
		
	func refresh_corner_points() -> void:
		for idx in corner_indexes:
			corner_points.append(outline_points[idx])


# This is a piece of street, in the abstract. However, there might be a
# hypothetical "StreetSegmentFrame", which might actually overshoot the
# boundaries and fill in gaps to nearby developments, for example.
## A piece of street, with data such as the main curve and boundaries.
class StreetSegment extends Node3D:
	var main_curve: Curve3D
	var radius: float
	# Since this class might support proper boundry Curve3Ds one day, these
	# two variables might be dropped later on.
	var _outer_boundary_points := PackedVector3Array()
	var _inner_boundary_points := PackedVector3Array()
	
	func _init(
		p_main_curve: Curve3D,
		p_radius: float
	) -> void:
		main_curve = p_main_curve
		radius = p_radius
	
	## Outer boundary points.
	func get_outer_boundary_points() -> PackedVector3Array:
		return _outer_boundary_points
	
	## Inner boundary points.
	func get_inner_boundary_points() -> PackedVector3Array:
		return _inner_boundary_points


# TODO: Curve initialization from layout.
# This will be added to a PositionerMultiComponent.
#class LayoutCurvePositioner extends CurvePositioner:
	#var _layout: Layout
	#var _proximal_curve_dirty = true
	#var proximal_curve := Curve3D.new():
		#get:
			#if _proximal_curve_dirty:
				#_update_proximal_curve()
			#return proximal_curve
	#var proximal_curve_linear
	#var _all_curves_dirty := true
	#var _all_curves: Array[Curve3D] = []:
		#get:
			#if _all_curves_dirty:
				#_update_all_curves()
			#return _all_curves
	#
	#func _init(p_layout: Layout) -> void:
		#_layout = p_layout
	#
	#func _update_proximal_curve() -> void:
		#_proximal_curve_dirty = false
	#
	#func _update_all_curves() -> void:
		#_all_curves.append(proximal_curve)
		#_all_curves_dirty = false
	#
	##==============================
	## Base class implementation
	#
	#func get_closest_point(p_reference_point: Vector3) -> Vector3:
		#var closest_point_candidates := PackedVector3Array()
		#
		#for curve in get_all_curves():
			#
		#
	#func get_all_curves() -> Array[Curve3D]:
		#return _all_curves


class LayoutCornerPositioner extends TaggablePositioner:
	var _layout: Layout
	
	func _init(p_layout: Layout) -> void:
		_layout = p_layout
		add_tags(["layout", "corner"])
	
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		return GeoFoo.get_closest_point(p_reference_point, _layout.corner_points)


class LayoutOutlinePositioner extends TaggablePositioner:
	var _layout: Layout
	
	func _init(p_layout: Layout) -> void:
		_layout = p_layout
		add_tags(["layout", "outline"])
	
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		return  GeoFoo.get_closest_point(p_reference_point, _layout.outline_points)


func generate_simple_row_house(
	
) -> Building:
	return Building.new()
