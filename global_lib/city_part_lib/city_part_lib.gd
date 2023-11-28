extends RefCounted
class_name CityPartLib

### Dependencies:
# - PartLib


### "Imports": PartLib
const PartControl := PartLib.PartControl
const PartConnector := PartLib.PartConnector
const Node3DTailedBone := PartLib.Node3DTailedBone
const DefaultConnectors := PartLib.DefaultConnectors


# At least Bottom Left Front and Bottom Right Front
class BasicBuildingPartControl extends PartControl:
	const BOTTOM_LEFT_FRONT_BONE_NAME := "Bottom_Left_Front"
	const BOTTOM_LEFT_FRONT_TAIL_BONE_NAME := BOTTOM_LEFT_FRONT_BONE_NAME + TAIL_SUFFIX
	const BOTTOM_RIGHT_FRONT_BONE_NAME := "Bottom_Right_Front"
	const BOTTOM_RIGHT_FRONT_TAIL_BONE_NAME := BOTTOM_RIGHT_FRONT_BONE_NAME + TAIL_SUFFIX
	
	var bottom_left_front_connector: PartConnector
	var bottom_right_front_connector: PartConnector
	
	# TODO [workaround-cleanup]: Remove _init when this is fixed:
	#   https://github.com/godotengine/godot/issues/70605
	#   Remove this TODO if the _init becomes permanent.
	func _init(p_to_be_controlled_part: Node3D):
		super._init(p_to_be_controlled_part)
	
	# TODO: Skeleton sanity check, based on a method in the base class
	#   which, in the base class, is factored into the decision whether to
	#   to go for a fallback skeleton. Crucially, in that case the fallbackish
	#   connector setup should be applied, not the overriden `_init_connectors`
	#   stuff.
	
	func _init_connectors() -> DefaultConnectors:
		bottom_left_front_connector = PartConnector.new(
			part,
			Node3DTailedBone.new(
				part,
				skeleton,
				skeleton.find_bone(BOTTOM_LEFT_FRONT_BONE_NAME),
				skeleton.find_bone(BOTTOM_LEFT_FRONT_TAIL_BONE_NAME)
			)
		)
		bottom_right_front_connector = PartConnector.new(
			part,
			Node3DTailedBone.new(
				part,
				skeleton,
				skeleton.find_bone(BOTTOM_RIGHT_FRONT_BONE_NAME),
				skeleton.find_bone(BOTTOM_RIGHT_FRONT_TAIL_BONE_NAME)
			)
		)
		return DefaultConnectors.new(
			bottom_left_front_connector,
			bottom_right_front_connector
		)
		
	
# At least Bottom Left Front, Bottom Right Front and Top Left Front for
# (semi-)subterranean parts (Top Left Front connects to upper Bottom Left Front).
class BasicFacadePartControl extends BasicBuildingPartControl:
	const TOP_LEFT_FRONT_BONE_NAME := "Top_Left_Front"
	const TOP_LEFT_FRONT_TAIL_BONE_NAME := TOP_LEFT_FRONT_BONE_NAME + TAIL_SUFFIX
	
	var top_left_front_connector: PartConnector
	
	# TODO [workaround-cleanup]: Remove _init when this is fixed:ttwitch
	#   https://github.com/godotengine/godot/issues/70605
	#   Remove this TODO if the _init becomes permanent.
	func _init(p_to_be_controlled_part: Node3D):
		super._init(p_to_be_controlled_part)

	func _init_connectors() -> DefaultConnectors:
		var default_connectors := super._init_connectors()
		
		top_left_front_connector = PartConnector.new(
			part,
			Node3DTailedBone.new(
				part,
				skeleton,
				skeleton.find_bone(TOP_LEFT_FRONT_BONE_NAME),
				skeleton.find_bone(TOP_LEFT_FRONT_TAIL_BONE_NAME)
			)
		)
		
		return default_connectors
	
	
# This is the transform class to perform Transform3D based transformations,
# as opposed to something like a `PartAnimationTransformer`, which would
# implement these operations using animations. Perhaps the "meat" of the
# functionality could also be in a configurable Delegate passed to _init.
# 
# We might also want to combine both approaches - with the above described
# approach we would have to subclass or write a new PartTransformer class
# every time we needed a new combination, which would be more or less of a
# limitation, depending on how many methods would be affected.
#
# One way to work around this would be to have an optional delegate parameter
# for every method. Note that this would make it so that the callsites of these
# methods would potentially concern themselves with which delegate to use,
# instead of it just being a concern of the site that instantiated the
# PartTransformer.
class PartTransformer:
	var part_control: PartControl
	var part_columns: int
	var part_rows: int
	#var part_layers: int
	var part_length: float
	#var part_height: float
	#var part_depth: float
	
	var part_length_per_column: float:
		get:
			return part_length / part_columns
	
	func _init(
		p_part_control: PartControl,
		p_part_columns: int,
		p_part_rows: int,
		#p_part_layers: int,
		p_part_length: float,
		#p_part_height: float
		#p_part_depth: float
	):
		part_control = p_part_control
		part_columns = p_part_columns
		part_rows = p_part_rows
		#part_layers = p_part_layers
		part_length = p_part_length
		#part_height = p_part_height
		#part_depth = p_part_depth
		
	func respan_to_columns(p_columns: int) -> void:
		#var new_part_length: float = part_length_per_column * columns
		var scaling_factor: float = float(p_columns) / float(part_columns)
		
		#print("part_columns:", part_columns, ", columns:", columns, ", scaling_factor:", scaling_factor)
		part_control.part.transform = part_control.part.transform * Transform3D(
			part_control.part.transform.basis.x * Vector3(scaling_factor, 1, 1),
			part_control.part.transform.basis.y * Vector3(scaling_factor, 1, 1),
			part_control.part.transform.basis.z * Vector3(scaling_factor, 1, 1),
			#part_control.part.transform.origin
			Vector3(0, 0, 0)
		)
		
		
static func respan_3_columns(
	p_left_part_transformer: PartTransformer,
	p_center_part_transformer: PartTransformer,
	p_right_part_transformer: PartTransformer,
	p_overall_columns: int,
	p_center_respan_factor: float = 1.0,
):
	var overall_column_span: float = 3.0
	var base_resize_factor: float = p_overall_columns / overall_column_span
	var center_resize_factor: float = base_resize_factor * p_center_respan_factor
	#print("center_resize_factor (%s) = " % center_resize_factor, base_resize_factor, " / ", center_respan_factor)
	var non_center_resize_factor: float = base_resize_factor + ((base_resize_factor - center_resize_factor) / (overall_column_span - 1.0))
	var non_center_part_columns: int = floor(non_center_resize_factor)
	var center_part_columns: int = non_center_part_columns + (p_overall_columns % non_center_part_columns)
	#print("center_part_columns:", center_part_columns, ", non_center_part_columns:", non_center_part_columns)
	
	p_left_part_transformer.respan_to_columns(non_center_part_columns)
	p_center_part_transformer.respan_to_columns(center_part_columns)
	p_right_part_transformer.respan_to_columns(non_center_part_columns)
