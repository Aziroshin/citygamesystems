extends WorldObject
class_name LayoutWorldObject

# Dependencies:
# - CityBuilder
# - PositionerLib

@export var layout: CityBuilder.Layout
@export var _colliders: Array[CollisionObject3D] = []


func _set_defaults() -> void:
	if not layout:
		layout = CityBuilder.Layout.new()


func create_positioner() -> PositionerLib.MultiPositioner:
	var multi_positioner := PositionerLib.MultiPositioner.new()
	var corner_positioner := CityBuilder.LayoutCornerPositioner.new(layout)
	var outline_positioner := CityBuilder.LayoutOutlinePositioner.new(layout)
	multi_positioner.add_positioner(corner_positioner)
	multi_positioner.add_positioner(outline_positioner)
	return multi_positioner


func get_colliders() -> Array[CollisionObject3D]:
	return _colliders

func add_collider(p_collider: CollisionObject3D) -> void:
	_colliders.append(p_collider)
	add_child(p_collider)
	collider_added.emit(self, p_collider)
