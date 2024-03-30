extends CityToolLib.CurveLayoutTool

## "Imports": CityToolLib
const CurveCursor = CityToolLib.CurveCursor

## Used to get the actual corresponding map points to our curve points.
signal request_map_points(source_points: PackedVector3Array)

enum LayoutToolMapRayCasterRequestTypeId {
	CURVE,
}
@export var map_agent: ToolLibMapAgent
@export var life_cyclers: WorldObjectLifeCyclers
## Used for the colliders the tool uses to detect the boundary and corners of
## the area it's working with. Not related to the colliders of the layout
## objects themselves.
@export var collision_radius := 1.0
@onready var cursor := CurveCursor.new(_get_curve_tool_type_state().curve)
@onready var last_mouse_position := Vector3()
var corner_colliders: Array[IndexedAreaToolCollider] = []
var boundary_colliders: Array[IndexedAreaToolCollider] = []

func activate() -> void:
	super()
	map_agent.mouse_button.connect(_on_map_mouse_button)
	map_agent.mouse_position_change.connect(_on_map_mouse_position_change)


func deactivate() -> void:
	super()
	map_agent.mouse_button.disconnect(_on_map_mouse_button)
	map_agent.mouse_position_change.disconnect(_on_map_mouse_position_change)


func add_node(
	p_position: Vector3,
	p_finalized: bool,
) -> int:
	cursor.current_idx = super(p_position, p_finalized)
	return cursor.current_idx


func add_node_with_collider(
		p_position: Vector3,
		p_finalized: bool,
	) -> int:
		var idx := add_node(p_position, p_finalized)
		
		var node_shape := SphereShape3D.new()
		node_shape.radius = collision_radius
		var node_collider := IndexedAreaToolCollider.new(
			self,
			node_shape,
			idx
		)
		map_agent.get_map_node().add_child(node_collider)
		node_collider.transform.origin = p_position
		node_collider.input_ray_pickable = false
		corner_colliders.append(node_collider)
		
		if idx > 0:
			var position_a := get_state().curve.get_point_position(idx - 2)
			var position_b := get_state().curve.get_point_position(idx - 1)
			
			var edge_shape := CylinderShape3D.new()
			edge_shape.radius = collision_radius
			edge_shape.height = (position_a - position_b).length()
			var boundary_collider := IndexedAreaToolCollider.new(
				self,
				edge_shape,
				idx - 2
			)
			map_agent.get_map_node().add_child(boundary_collider)
			
			var z_at := (position_b - position_a).normalized()
			var x_at := Vector3.UP.cross(z_at).normalized()
			var y_at := z_at.cross(x_at).normalized()
			var basis_at := Basis(x_at, z_at, y_at)
			boundary_collider.transform = Transform3D(
				basis_at,
				position_a.lerp(position_b, 0.5)
			)
			
			boundary_collider.input_ray_pickable = false
			boundary_colliders.append(boundary_collider)
		
		return idx

func _on_map_mouse_button(
	_p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	var tool_position := map_agent.get_position(p_mouse_position)
	
	if tool_position == cursor.previous_position_ro:
		return
		
	if get_node_count() >= 3:
		var second_previous_position := get_state().curve.get_point_position(cursor.current_idx-2)
		var previous_to_second_previous := second_previous_position - cursor.previous_position_ro
		var previous_to_current :=  cursor.current_position_ro - cursor.previous_position_ro
		if previous_to_second_previous.normalized().dot(previous_to_current.normalized()) > 0.9:
			# TODO: Give proper (visual) feedback.
			print("[Layout Tool]: Angle too narrow.")
			return
		
	# TODO: This will need to be properly tied into actions, but also in
	# a way modular enough that it won't be a pain to integrate the tool into
	# other codebases.
	if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.pressed:
		if get_node_count() == 0:
			add_node_with_collider(
				tool_position,
				UNFINALIZED
			)
		if get_node_count() >= 2:
			add_node_with_collider(
				tool_position,
				UNFINALIZED
			)
		
		Cavedig.needle(
			map_agent.get_map_node(),
			Transform3D(Basis(), get_state().curve.get_point_position(cursor.current_idx))
		)
		
		if get_node_count() >= 3\
		and map_agent.get_position(p_mouse_position) == get_state().curve.get_point_position(0):
			_on_request_build_layout()


func _on_map_mouse_position_change(
	_p_camera: Camera3D,
	_p_event: InputEvent,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	var tool_position := map_agent.get_position(p_mouse_position)
	if get_node_count() == 1 and not p_mouse_position == cursor.current_position_ro:
		cursor.current_idx = add_node(p_mouse_position, FINALIZED)
	if get_node_count() >= 2:
		
		if tool_position == cursor.previous_position_ro:
			return
			
		for i_node in get_state().curve.point_count:
			var node_position := get_state().curve.get_point_position(i_node)
			if\
			not i_node == 0\
			and not i_node == get_last_node_idx()\
			and tool_position == node_position:
				# TODO: Give proper (visual) feedback.
				print("[LayoutTool] Can't place new corner on an existing one.")
				return
		
		var first_node_position := get_state().curve.get_point_position(0)
		var current_segment_node_a := cursor.previous_position_ro
		var current_segment_node_b := tool_position
		
		for i_node in get_state().curve.point_count - 3:
			var other_segment_node_a := get_state().curve.get_point_position(i_node)
			var other_segment_node_b := get_state().curve.get_point_position(i_node+1)
			 
			# [UNSAFE: BEGIN]
			# Returns Variant: null or Vector2
			#match Geometry2D.segment_intersects_segment(
				#Vector2(current_segment_node_a.x, current_segment_node_a.z),
				#Vector2(current_segment_node_b.x, current_segment_node_b.z),
				#Vector2(other_segment_node_a.x, other_segment_node_a.z),
				#Vector2(other_segment_node_b.x, other_segment_node_b.z)
			#):
				#null:
					#pass
				#var intersection_point_vector2:
					#if not tool_position == first_node_position:
						## TODO: Give proper (visual) feedback.
						#print("[LayoutTool] Layout boundary can't intersect itself.")
						#return
			# [UNSAFE: END]
			
			
		set_node_position(cursor.current_idx, tool_position, UNFINALIZED)
		
		var current_node_in_point := cursor.previous_position_ro - cursor.current_position_ro
		var current_node_out_point := cursor.current_position_ro- cursor.previous_position_ro
		var previous_node_out_point := cursor.current_position_ro - cursor.previous_position_ro
		
		set_node_handle_in_point(
			cursor.current_idx,
			current_node_in_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.current_idx,
			current_node_out_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.previous_idx_ro,
			previous_node_out_point,
			UNFINALIZED
		)


# For quick & dirty debugging.
func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			# Perhaps using signals to communicate that a new layout has been
			# made, or a layout got edited might be an alternative to consider?
			# It would decouple the tool a little bit more, but also add
			# indirection in turn.
			_spawn_new_layout_object(_create_corner_only_layout_object())
			# TODO [bug]: This is also disabling the street tool when it's
			# active. However, the layout tool shouldn't be able to do that
			# when its its deactivation routine is triggered.
			deactivate()


func _create_corner_only_layout_object() -> LayoutWorldObject:
	var corner_points := PackedVector3Array()
	for i_point in get_state().curve.point_count:
		corner_points.append(get_state().curve.get_point_position(i_point))
	return life_cyclers.layout.create_from_corner_points(corner_points)


func _spawn_new_layout_object(layout_object: LayoutWorldObject) -> void:
	map_agent.get_map_node().add_child(layout_object)
	layout_object.transform.origin = map_agent.get_position(last_mouse_position)


func _on_request_build_layout() -> void:
	_spawn_new_layout_object(_create_corner_only_layout_object())

	
	# StreetMesh based verification that the basic layout chain-of-call works
	# for debugging and stuff. Can be removed later.
	#request_map_points.emit(
		#ToolMapRayCaster.Request.new(
			#LayoutToolMapRayCasterRequestTypeId.CURVE,
			#get_state().curve.get_baked_points()
		#)
	#)
	# Now it's up to `ToolMapRayCaster` to answer back. Once it does,
	# `_on_result_map_points` below will be kicked off.


func _on_result_map_points(p_result: ToolMapRayCaster.Result) -> void:
	for point in p_result.map_points:
		Cavedig.needle(
			map_agent.get_map_node(),
			Transform3D(Basis(), point),
			Vector3(0.85, 0.1, 0.75),
			0.3,
			0.02
		)
	_build_layout(p_result.map_points)


func _build_layout(p_map_points: PackedVector3Array) -> void:
	
	#----- Build Layout
	_add_layout_to_map(
		_create_layout(
			p_map_points
		)
	)


func _create_layout(p_map_points: PackedVector3Array) -> MeshInstance3D:
	var profile2d := PackedVector2Array([
		Vector2(0.5, 0.1),
		Vector2(0.5, -0.1),
		Vector2(-0.5, -0.1),
		Vector2(-0.5, 0.1)
	])
	var transforms: Array[Transform3D] = []
	
	for i_map_point in range(len(p_map_points)):
		transforms.append(
			Transform3D(
				GeoFoo.get_baked_point_transform(get_state().curve, i_map_point).basis,
				p_map_points[i_map_point]
			)
		)
	
	return StreetMesh.create_network_segment(
		p_map_points,
		transforms,
		profile2d
	)


func _add_layout_to_map(p_street_mesh: MeshInstance3D) -> void:
	map_agent.get_map_node().add_child(p_street_mesh)
