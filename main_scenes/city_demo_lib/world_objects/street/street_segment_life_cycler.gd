extends CityGameWorldObjectLifeCycler
class_name StreetSegmentWorldObjectLifeCycler

# Dependencies:
# - CityBuilder.StreetSegment


func create() -> StreetSegmentWorldObject:
	return StreetSegmentWorldObject.new()


# Misc notes:
#   Mesh(es) should be optional - a street segment could be represented by a
#   shader, for example. But the collision would still have to be there.
