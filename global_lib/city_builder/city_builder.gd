extends RefCounted
class_name CityBuilder


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
		for proximal_point in layout.proximal_outline_points:
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
class Layout extends Node3D:
	var proximal_outline_points: PackedVector3Array
	var corner_indexes: PackedVector3Array
	var distal_outline: LayoutDistalOutline
	
	func _init(
		p_proximal_outline_points := PackedVector3Array(),
		p_corner_indexes := PackedVector3Array(),
		p_distal_outline := LayoutDistalOutline.new(self)
	):
		proximal_outline_points = p_proximal_outline_points
		corner_indexes = p_corner_indexes
		distal_outline = p_distal_outline


func generate_simple_row_house(
	
) -> Building:
	return Building.new()
