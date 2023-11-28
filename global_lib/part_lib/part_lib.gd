extends RefCounted
class_name PartLib


const SKELETON_SUFFIX: StringName = "Skeleton"
const SKELETON_NODE_NAME: StringName = "Skeleton3D"
const BOTTOM_LEFT_FRONT_BONE: StringName = "Bottom_Left_Front"
const BOTTOM_RIGHT_FRONT_BONE: StringName = "Bottom_Right_Front"


# Represents a bone on a Skeleton3D which belongs to a Node3D.
# Provides handy methods for working with bones as indicators
# of particular positions on the node, especially in relation
# to gobal space.
class Node3DBone:
	var node: Node3D
	var skeleton: Skeleton3D
	var idx: int
	
	func _init(
		p_node_with_skeleton: Node3D,
		p_skeleton_of_node: Skeleton3D,
		p_bone_idx: int
	):
		idx = p_bone_idx
		skeleton = p_skeleton_of_node
		node = p_node_with_skeleton
		
	func get_transform() -> Transform3D:
		return skeleton.get_bone_global_pose(idx)
	
	func get_global_transform() -> Transform3D:
		return Transform3D(
			node.global_transform.basis,
			node.to_global(get_transform().origin)
		)
		
# `Node3DBone` which represents a bone with a child bone that denotes
# where its tail is.
# 
# Design Note:
# Having a distinct class for this allows us to express the presence
# of a tail bone as a static type.
class Node3DTailedBone extends Node3DBone:
	var tail: Node3DBone
	
	func _init(
		p_node_with_skeleton: Node3D,
		p_skeleton_of_node: Skeleton3D,
		p_this_bone_idx: int,
		p_tail_bone_idx: int
	):
		super(
			p_node_with_skeleton,
			p_skeleton_of_node,
			p_this_bone_idx
		)
		tail = Node3DBone.new(
			p_node_with_skeleton,
			p_skeleton_of_node,
			p_tail_bone_idx
		)
		
	func get_global_transform() -> Transform3D:
		return Transform3D(
			node.global_transform.basis,
			node.to_global(get_transform().origin)
		)
		
	func get_direction() -> Vector3:
		return tail.get_transform().origin


class PartConnector:
	var part: Node3D
	var bone: Node3DTailedBone
	
	func _init(
		p_corresponding_part: Node3D,
		p_connector_bone: Node3DTailedBone
	):
		part = p_corresponding_part
		bone = p_connector_bone
		
	# Returns the transform with respect to its parent part.
	#
	# Not to be confused with `get_transform_to_part_parent`, which returns the
	# transform with respect to the _transform_ of its parent part.
	func get_transform() -> Transform3D:
		return bone.get_transform()
		
	# Returns the transform with respect to the transform of its parent part.
	#
	# Hint: This is the method that gets you the transform "properly"
	# relative to the part's parent. ;)
	func get_transform_to_part_parent() -> Transform3D:
		return part.transform * get_transform()
		
	func get_origin_to_part_parent() -> Vector3:
		return get_transform_to_part_parent().origin
		
	func get_global_transform() -> Transform3D:
		return bone.get_global_transform()
		
	func get_direction() -> Vector3:
		return bone.get_direction()


class DefaultConnectors:
	var receiving: PartConnector
	var docking: PartConnector
	
	func _init(p_receiving: PartConnector, p_docking: PartConnector):
		receiving = p_receiving
		docking = p_docking


class PartControl:
	const SKELETON_NODE_NAME := "Skeleton3D"
	const TAIL_SUFFIX = "_Tail"
	# These bones can only be expected to be available on the fallback skeleton,
	# unless, by coincidence, the part's skeleton has such bones too.
	# If you have this case and you need constants, just make them without the
	# preceding `_` (underscore). Don't use this for error-checking, use
	# `is_using_fallback_skeleton` instead.
	const _FALLBACK_BONE_NAME := "_Fallback"
	const _FALLBACK_TAIL_BONE_NAME := "_Fallback" + TAIL_SUFFIX
	
	var part: Node3D
	var skeleton: Skeleton3D
	# If `true`, something went wrong with getting the skeleton from the part.
	var is_using_fallback_skeleton := false
	
	# If we're using the fallback skeleton, these two will simply default
	# to the same connector, just like a regular part with one connector bone
	# would.
	var default_receiving_connector: PartConnector
	var default_docking_connector: PartConnector
	
	func _init(p_to_be_controlled_part: Node3D):
		part = p_to_be_controlled_part
		if not _init_usable_skeleton_from_part(part):
			_init_fallback_skeleton()
		var default_connectors := _init_connectors()
		default_receiving_connector = default_connectors.receiving
		default_docking_connector = default_connectors.docking
		
	func transform_to_connector(p_connector: PartConnector):
		part.transform = p_connector.get_transform_to_part_parent()
		
	func origin_to_connector(p_connector: PartConnector):
		part.transform.origin = p_connector.get_origin_to_part_parent()
		
	# Connector for the fallback skeleton, but works with any other skeleton
	# which has at least two bones, with one of them having a name which
	# ends in the value of `TAIL_SUFFIX` (which, ideally, would also be
	# positioned like a tail bone, otherwise surprising results may ensue).
	func _create_fallbackish_connector() -> PartConnector:
		var bone_idx: int
		var bone_name: StringName
		var bone_tail_idx: int
		
		# Get any bone name which doesn't end with the value of `TAIL_SUFFIX`.
		for idx in range(0, skeleton.get_bone_count()):
			var prospective_bone_name := skeleton.get_bone_name(idx)
			if not str(prospective_bone_name).ends_with(TAIL_SUFFIX):
				bone_idx = idx
				bone_name = prospective_bone_name
				
		# Get tail bone name.
		for idx in range(0, skeleton.get_bone_count()):
			if skeleton.get_bone_name(idx) == str(bone_name) + TAIL_SUFFIX:
				bone_tail_idx = idx
		
		return PartConnector.new(
			part,
			Node3DTailedBone.new(
				part,
				skeleton,
				bone_idx,
				bone_tail_idx
			)
		)
		
	func _create_default_connector() -> PartConnector:
		return _create_fallbackish_connector()
		
	func _init_connectors() -> DefaultConnectors:
		var default_connector := _create_fallbackish_connector()
		return DefaultConnectors.new(
			default_connector,
			default_connector
		)
		
	func _init_usable_skeleton_from_part(
		p_node: Node3D,
		p_err_if_skeleton_missing = true
	) -> bool:
		var children = p_node.get_children()#[0].get_node(SKELETON_NODE_NAME)
		print(p_node.name)
		for child in children:
			print("after suffix")
			var skeleton_with_maybe_too_few_bones = child.get_node(SKELETON_NODE_NAME)
			# TODO: If the fallback skeleton manages with only 1 bone, this
			# should too. Look into it.
			if skeleton_with_maybe_too_few_bones.get_bone_count() >= 2:
				print("after too few bones")
				skeleton = skeleton_with_maybe_too_few_bones # Has enough bones. :p
				return true
		if p_err_if_skeleton_missing:
			var err = "Couldn't find a skeleton for %s" % p_node
			push_error(err)
			assert(false, err)
		return false
		
	func _init_fallback_skeleton() -> void:
		var new_skeleton := Skeleton3D.new()
		new_skeleton.add_bone(_FALLBACK_BONE_NAME)
		is_using_fallback_skeleton = true
		skeleton = new_skeleton
