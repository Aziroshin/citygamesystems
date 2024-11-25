extends WorldObject
class_name LayoutWorldObject

# Dependencies:
# - CityBuilder
# - PositionerLib

@export var layout: CityBuilder.Layout


func _set_defaults() -> void:
	if not layout:
		layout = CityBuilder.Layout.new()


func create_positioner() -> PositionerLib.MultiPositioner:
	var multi_positioner := PositionerLib.MultiPositioner.new()
	var corner_positioner := PositionerLib.NodeRelativeWrappedPositioner.new(
		self,
		CityBuilder.LayoutCornerPositioner.new(layout)
	)
	var outline_positioner := PositionerLib.NodeRelativeWrappedPositioner.new(
		self,
		CityBuilder.LayoutOutlinePositioner.new(layout)
	)
	multi_positioner.add_positioner(corner_positioner)
	multi_positioner.add_positioner(outline_positioner)
	return multi_positioner

