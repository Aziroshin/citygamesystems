@tool
extends Node3D

### "Imports": MeshLib
const AHorizontallyFoldedPlane := MeshLib.AHorizontallyFoldedPlane
const AHorizontallyFoldedTriangle := MeshLib.AHorizontallyFoldedTriangle
const AFoldedPlane := MeshLib.AFoldedPlane
const AMultiSegment := MeshLib.AMultiSegment
const AQuad := MeshLib.AQuad
const ATri := MeshLib.ATri
const ASubdividedLine := MeshLib.ASubdividedLine

### "Imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay

### "Imports": CityPartLib
const PartTransformer := CityPartLib.PartTransformer

@onready var RoofDoublePitchedSide: Resource = load("res://assets/parts/roof_double_pitched_side.gltf")
@onready var RoofDoublePitchedCorner: Resource = load("res://assets/parts/roof_double_pitched_corner.gltf")
@onready var RoofDoublePitchedSideForkedGableWing: Resource = load("res://assets/parts/roof_double_pitched_forked_gable_wing.gltf")
@onready var Facade: Resource = load("res://assets/parts/facade_d.gltf")


func _mess_blender_house() -> Node3D:
	# These values might be sourced from somewhere else at some point.
	# They represent the specification for parts, a standard. They shouldn't be
	# understood as defaults (but may coincidentally end up as defaults).
	var standard_part_length: float = 0.5
	var standard_part_columns: int = 16
	var standard_part_rows: int = 16
	
	# Part metadata assumptions
	var house_facade_columns: int = 64
	# Semi-basement lowers it by 8.
	var house_facade_rows: int = 56
	
	var house: Node3D = Node3D.new()
	
	# Sides.
	var side_1_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSide.instantiate())
	var side_2_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSide.instantiate())
	var side_3_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSide.instantiate())
	var side_4_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSide.instantiate())
	
	# Forked gable wings.
	var mid_1_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSideForkedGableWing.instantiate())
	var mid_2_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSideForkedGableWing.instantiate())
	var mid_3_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSideForkedGableWing.instantiate())
	var mid_4_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedSideForkedGableWing.instantiate())
	
	# Corners.
	var corner_1_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedCorner.instantiate())
	var corner_2_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedCorner.instantiate())
	var corner_3_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedCorner.instantiate())
	var corner_4_control: CityPartLib.BasicBuildingPartControl = CityPartLib.BasicBuildingPartControl.new(RoofDoublePitchedCorner.instantiate())
	
	# Facades.
	var facade_1_control: CityPartLib.BasicFacadePartControl = CityPartLib.BasicFacadePartControl.new(Facade.instantiate())
	var facade_2_control: CityPartLib.BasicFacadePartControl = CityPartLib.BasicFacadePartControl.new(Facade.instantiate())
	var facade_3_control: CityPartLib.BasicFacadePartControl = CityPartLib.BasicFacadePartControl.new(Facade.instantiate())
	var facade_4_control: CityPartLib.BasicFacadePartControl = CityPartLib.BasicFacadePartControl.new(Facade.instantiate())
	
	var part_controls: Array[CityPartLib.BasicBuildingPartControl] = [
		#side_1_control, side_2_control, side_3_control, side_4_control
		#corner_1_control, corner_2_control, corner_3_control, corner_4_control,
		#mid_1_control, mid_2_control, mid_3_control, mid_4_control,
		facade_1_control, facade_2_control, facade_3_control, facade_4_control
	]
	
	for part_control in part_controls:
		house.add_child(part_control.part)
		Cavedig.set_bone_indicators(part_control.skeleton)
	
	# Facade.
	facade_2_control.transform_to_connector(facade_1_control.bottom_right_front_connector)
	facade_2_control.part.transform = facade_2_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
	facade_3_control.transform_to_connector(facade_2_control.bottom_right_front_connector)
	facade_3_control.part.transform = facade_3_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
	facade_4_control.transform_to_connector(facade_3_control.bottom_right_front_connector)
	facade_4_control.part.transform = facade_4_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
	
	### Roof.
	#side_1_control.transform_to_connector(facade_1_control.top_left_front_connector)
	#side_2_control.transform_to_connector(side_1_control.bottom_right_front_connector)
	#side_3_control.transform_to_connector(side_2_control.bottom_right_front_connector)
	
	var roof_columns := standard_part_columns
	var roof_length := standard_part_length
	# TODO: The test parts are a bit higher than 5. Rework parts to fit.
	var roof_rows: int = 5
	
	
	var corner_1_transformer := PartTransformer.new(
		corner_1_control,
		roof_columns,
		roof_rows,
		roof_length
	)
	
	var mid_1_transformer := PartTransformer.new(
		mid_1_control,
		roof_columns,
		roof_rows,
		roof_length
	)
	
	var corner_2_transformer := PartTransformer.new(
		corner_2_control,
		roof_columns,
		roof_rows,
		roof_length
	)
	
	### respan_3_columns testbed
	CityPartLib.respan_3_columns(
		corner_1_transformer,
		mid_1_transformer,
		corner_2_transformer,
		house_facade_columns,
		1.35
	)
	
	corner_1_control.origin_to_connector(facade_1_control.top_left_front_connector)
	mid_1_control.origin_to_connector(corner_1_control.bottom_right_front_connector)
	
	# Corner 2.
	corner_2_control.origin_to_connector(mid_1_control.bottom_right_front_connector)
	# Rotate Corner 2, but offset the origin to the proper pivot first.
	corner_2_control.origin_to_connector(corner_2_control.bottom_right_front_connector)
	corner_2_control.part.transform = corner_2_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
	mid_2_control.origin_to_connector(corner_2_control.bottom_right_front_connector)
	
	#	### Working roof setup (but not stretched properly)
#	# Corner 3.
#	corner_3_control.transform_to_connector(mid_2_control.bottom_right_front_connector)
#	# Rotate Corner 3, but offset the origin to the proper pivot first.
#	corner_3_control.transform_to_connector(corner_3_control.bottom_right_front_connector)
#	corner_3_control.part.transform = corner_3_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
#	mid_3_control.transform_to_connector(corner_3_control.bottom_right_front_connector)
#	# Corner 4.
#	corner_4_control.transform_to_connector(mid_3_control.bottom_right_front_connector)
#	# Rotate Corner 3, but offset the origin to the proper pivot first.awaw
#	corner_4_control.transform_to_connector(corner_4_control.bottom_right_front_connector)
#	corner_4_control.part.transform = corner_4_control.part.transform.rotated_local(Vector3(0, 1, 0), PI/2)
#	mid_4_control.transform_to_connector(corner_4_control.bottom_right_front_connector)
	
	
	
	#mid_1_control.transform_to_connector(facade_1_control.top_left_front_connector)
	#side_1_control.transform_to_connector(corner_1_control.bottom_right_front_connector)
	
	# TODO: Maybe make a skeleton sanity check out of this. xD
#	for bone_idx in range(0, mid_1_control.skeleton.get_bone_count()):
#	print(mid_1_control.skeleton.get_bone_name(bone_idx))
	
	
	### Messing around with ArrayMesh roof stuff. Yep, all in the same _ready
	# function. I am going there. xD
	
	var array_mesh: ArrayMesh = ArrayMesh.new()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	
	var surface_arrays = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	
	var bottom_left := Vector3(0, 0, 0)
	var top_left := Vector3(0, 1, 0)
	var top_right := Vector3(1, 1, 0)
	var bottom_right := Vector3(1, 0, 0)
	var tri_top := Vector3(0.5, 1, 0)
	
	var quad := AQuad.new(bottom_left, top_left, top_right, bottom_right)
	quad.apply_all()
	
	var quad2 := AQuad.new(bottom_left, top_left, top_right, bottom_right)
	quad2.transform = quad2.transform.translated(Vector3(1, 0, 0)).rotated_local(Vector3(0, 1, 0), PI/2)
	quad2.apply_all()
	var tri := ATri.new(bottom_left, tri_top, bottom_right)
	
	# Works, but only with Basis(). If taking the basis from quad2.transform,
	# it fails.
	tri.transform = quad2.transform * Transform3D(Basis(), quad2.bottom_right.untransformed)
	
	# Same effect as `quad2.transform.translated(quad2.bottom_right.untransformed)`,
	# like below.
	#tri.transform = Transform3D(Basis(), quad2.bottom_right.untransformed) * quad2.transform
	
	# Doesn't work - shows Tri in parallel to quad2, like above.
	#tri.transform = quad2.transform.translated(quad2.bottom_right.untransformed)
	
	tri.apply_all()
	# This...
	#tri.bottom_left.untransformed = (Transform3D(Basis(), quad2.top_right.transformed).affine_inverse() * Transform3D(Basis(), tri.bottom_left.transformed) ).origin
	# ... seems to produce an equivalent result to this:
	#tri.bottom_left.untransformed =  quad2.top_right.transformed - tri.bottom_left.transformed
	
	# This works so far.
	tri.bottom_left.translate_to_transformed(quad2.top_right)
	tri.apply_all()
	
	surface_arrays[ArrayMesh.ARRAY_VERTEX] =\
		quad.get_array_vertex()\
		+ quad2.get_array_vertex()\
		+ tri.get_array_vertex()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	mesh_instance.mesh = array_mesh
	var material = load("res://dev/cavedig/cavedig_material.tres")
	mesh_instance.material_override = material
	
	# Comment in to view above test.
	#add_child(mesh_instance)
	#add_child(GeoFuncs.get_array_mesh_node(surface_arrays))
	
	return house
	
	
func _ready() -> void:
	add_child(_mess_blender_house())
