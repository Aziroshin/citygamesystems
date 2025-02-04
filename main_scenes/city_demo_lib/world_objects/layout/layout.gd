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
	var multi_positioner := PositionerLib.RadiusPrioritizingMultiPositioner.new()
	var corner_positioner := PositionerLib.NodeRelativeWrappedPositioner.new(
		self,
		CityBuilder.LayoutCornerPositioner.new(layout)
	)
	var outline_positioner := PositionerLib.NodeRelativeWrappedPositioner.new(
		self,
		CityBuilder.LayoutOutlinePositioner.new(layout)
	)
	var unwrapped_lerped_outline_positioner := PositionerLib.LerpedPointsGetterPositioner.new(
			PositionerLib.StaticFromArrayReferencePointsGetter.new(layout.outline_points)
	)
	unwrapped_lerped_outline_positioner.add_tags(["lerped", "outline", "layout"])
	var lerped_outline_positioner := PositionerLib.NodeRelativeWrappedPositioner.new(
		self,
		unwrapped_lerped_outline_positioner
	)
	multi_positioner.add_positioner(corner_positioner)
	multi_positioner.add_positioner(outline_positioner)
	multi_positioner.add_positioner(lerped_outline_positioner)
	return multi_positioner
