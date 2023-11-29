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
		
		
func generate_simple_row_house(
	
) -> Building:
	return Building.new()
