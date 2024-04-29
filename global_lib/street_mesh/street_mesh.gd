extends RefCounted
class_name StreetMesh


static func create_network_segment(
	p_points: PackedVector3Array,
	p_point_transforms: Array[Transform3D],
	p_profile2d: PackedVector2Array,
) -> MeshInstance3D:
	var cap2d := PackedVector2Array()
	var profile3d := PackedVector3Array()
	var new_mesh_instance3d := MeshInstance3D.new()
	
	profile3d = PackedVector3Array()
	for vertex2d in p_profile2d:
		profile3d.append(Vector3(vertex2d.x, vertex2d.y, 0.0))
	
	for idx in Geometry2D.triangulate_polygon(p_profile2d):
		cap2d.append(p_profile2d[idx])
		
	var vertices := create_street_vertices(
		p_points,
		p_point_transforms,
		profile3d,
		cap2d,
	)
	
	new_mesh_instance3d.mesh = GeoFoo.create_array_mesh(vertices)
	#new_mesh_instance3d.mesh.surface_set_material(0, material)
	
	#var debug_overlay := MeshDebugLib.ADebugOverlay.new()
	#debug_overlay.show_labels(false)
	#debug_overlay.show_vertex_indicators(true)
	#new_mesh_instance3d.add_child(debug_overlay)
	#debug_overlay.visualize_array_vertex(vertices)
	
	return new_mesh_instance3d

static func get_cap3d(p_cap2d, p_inverted: bool) -> PackedVector3Array:
	assert(len(p_cap2d) % 3 == 0)
	
	var vertices := PackedVector3Array()
	vertices.resize(len(p_cap2d))
	
	for i_tri in range(0, len(p_cap2d), 3):
		vertices[i_tri] = Vector3(p_cap2d[i_tri].x, p_cap2d[i_tri].y, 0.0)
		if p_inverted:
			vertices[i_tri+1] = Vector3(p_cap2d[i_tri+2].x, p_cap2d[i_tri+2].y, 0.0)
			vertices[i_tri+2] = Vector3(p_cap2d[i_tri+1].x, p_cap2d[i_tri+1].y, 0.0)
		else:
			vertices[i_tri+1] = Vector3(p_cap2d[i_tri+1].x, p_cap2d[i_tri+1].y, 0.0)
			vertices[i_tri+2] = Vector3(p_cap2d[i_tri+2].x, p_cap2d[i_tri+2].y, 0.0)
		
	return vertices


static func create_street_vertices(
	p_points: PackedVector3Array,
	p_point_transforms: Array[Transform3D],
	p_profile: PackedVector3Array,
	p_cap2d: PackedVector2Array
) -> PackedVector3Array:
	assert(len(p_points) >= 2)
	assert(len(p_points) == len(p_point_transforms))
	
	var point_loops: Array[PackedVector3Array] = []
	var vertices := PackedVector3Array()
	
	# Initialize `point_loops` with loops transformed along the curve.
	for i_point in len(p_points):
		var current_loop := PackedVector3Array()
		var point_transform := p_point_transforms[i_point]
		
		for vertex in p_profile:
			var transformed_vertex := point_transform.basis * vertex + point_transform.origin
			current_loop.append(transformed_vertex)
			
		point_loops.append(current_loop)
	
	# Make first cap.
	vertices += GeoFoo.to_transformed(
		get_cap3d(p_cap2d, true),
		p_point_transforms[0]
	)
	
	# We're skipping the the last loop, as this is expecting a "next"
	# loop in order to work - the last loop will already have been integrated
	# by the iteration pertaining to its previous loop.
	for i_loop in len(point_loops) - 1:
		vertices = vertices + GeoFoo.get_loop_to_loop_extruded(
			point_loops[i_loop],
			point_loops[i_loop+1]
		)
	
	# Make second cap:
	vertices += Curve3DDebugFuncs.to_transformed(
		get_cap3d(p_cap2d, false),
		p_point_transforms[len(p_points)-1]
	)
	
	return vertices
