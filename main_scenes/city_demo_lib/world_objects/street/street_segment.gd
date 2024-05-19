extends WorldObject
class_name StreetSegmentWorldObject

var street_segment: CityBuilder.StreetSegment

var world_object := WorldObject.get_from_collider_or_null(collider)
if world_object:
	pass
