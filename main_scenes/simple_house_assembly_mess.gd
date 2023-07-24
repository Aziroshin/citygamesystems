@tool
extends Node3D


### "Imports": CityBuilder
const HouseFrame := CityBuilder.HouseFrame
const HouseSide := CityBuilder.HouseSide
const HouseSideExposedness := CityBuilder.HouseSideExposedness
const HouseSideKinds := CityBuilder.HouseSideKinds


@onready var RoofDoublePitchedSide: Resource = load("res://assets/parts/roof_double_pitched_side.gltf")
@onready var RoofDoublePitchedCorner: Resource = load("res://assets/parts/roof_double_pitched_corner.gltf")
@onready var RoofDoublePitchedSideForkedGableWing: Resource = load("res://assets/parts/roof_double_pitched_forked_gable_wing.gltf")
@onready var FacadeB: Resource = load("res://assets/parts/facade_b.gltf")


func _mess_simple_house_assembly() -> Node3D:
	### For later, not used yet:
	# These values might be sourced from somewhere else at some point.
	# They represent the specification for parts, a standard. They shouldn't be
	# understood as defaults (but may coincidentally end up as defaults).
	var standard_part_length: float = 0.5
	var standard_part_columns: int = 16
	var standard_part_rows: int = 16
	
	# Part metadata assumptions.
	var house_facade_columns: int = 64
	# Semi-basement lowers it by 8.
	var house_facade_rows: int = 56
	###
	
	var house: Node3D = Node3D.new()
	
	var outline := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(0, 0, -1),
		Vector3(-1, 0, -1),
		Vector3(1, 0, 0),
	])
	var frame := HouseFrame.new([
		HouseSide.new(
			outline.slice(0, 2),
			HouseSideKinds.FREE,
			HouseSideExposedness.BUSY
		),
		HouseSide.new(
			outline.slice(1, 3),
			HouseSideKinds.FREE,
			HouseSideExposedness.BUSY
		),
		HouseSide.new(
			outline.slice(2, 4),
			HouseSideKinds.FREE,
			HouseSideExposedness.BUSY
		),
		HouseSide.new(
			PackedVector3Array([outline[len(outline)-1], outline[0]]),
			HouseSideKinds.FREE,
			HouseSideExposedness.BUSY
		),
	])
	
	var facades: Array[CityPartLib.BasicBuildingPartControl] = [
		CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSide.instantiate())
	]
	for side in frame.sides:
		var facade := CityPartLib.BasicBuildingPartControl.new(FacadeB.instantiate())
		# TODO: Resize facade using side.start_to_end.length
		facades.append(facade)
	
	var part_controls: Array[CityPartLib.BasicBuildingPartControl] = facades
	
	for part_control in part_controls:
		house.add_child(part_control.part)
		Cavedig.set_bone_indicators(part_control.skeleton)
	
	return house
	
	
func _mess_roofed_facade_house() -> Node3D:
	var mess_node := Node3D.new()
	
	# TODO
	
	return mess_node
	
	
func _ready() -> void:
	add_child(_mess_simple_house_assembly())
	
	
### Salvage.

# TODO: Maybe make a skeleton sanity check out of this. xD
#	for bone_idx in range(0, mid_1_control.skeleton.get_bone_count()):
#		print(mid_1_control.skeleton.get_bone_name(bone_idx))


# Quick hack to loop in tool mode for fast experimenting.
#var accumulated_delta := 0.0
#func ready_for_next_tick(delta, tick_interval: float) -> bool:
#	if accumulated_delta <= tick_interval:
#		# Not ready.
#		accumulated_delta += delta
#		return false
#	# Ready.
#	accumulated_delta = 0.0
#	return true


#enum GridDirection {
#	ROWS,
#	COLUMNS,
#	LAYERS
#}
