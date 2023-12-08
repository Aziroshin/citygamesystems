extends Node3D
class_name Curve3DMesh

@export var profile3d := PackedVector3Array()
@export var cap2d := PackedVector2Array()
@export var profile2d := PackedVector2Array():
	set(p_new_profile2d):
		profile2d = p_new_profile2d
		
		profile3d = PackedVector3Array()
		for vertex2d in p_new_profile2d:
			profile3d.append(Vector3(vertex2d.x, vertex2d.y, 0.0))
		
		cap2d = PackedVector2Array()
		for idx in Geometry2D.triangulate_polygon(p_new_profile2d):
			cap2d.append(p_new_profile2d[idx])
@export var material := Material
@export var curve := Curve3D.new()


func get_point_transform(point_idx: int) -> Transform3D:
	return curve.sample_baked_with_rotation(
		curve.get_closest_offset(
			curve.get_point_position(point_idx)
		)
	)
	
	
func get_baked_point_transform(
	idx: int,
) -> Transform3D:
	return curve.sample_baked_with_rotation(
		curve.get_closest_offset(
			curve.get_baked_points()[idx]
		)
	)


func get_cap3d(p_inverted: bool) -> PackedVector3Array:
	assert(len(cap2d) % 3 == 0)
	
	var vertices := PackedVector3Array()
	vertices.resize(len(cap2d))
	
	for i_tri in range(0, len(cap2d), 3):
		vertices[i_tri] = Vector3(cap2d[i_tri].x, cap2d[i_tri].y, 0.0)
		if p_inverted:
			vertices[i_tri+1] = Vector3(cap2d[i_tri+2].x, cap2d[i_tri+2].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d[i_tri+1].x, cap2d[i_tri+1].y, 0.0)
		else:
			vertices[i_tri+1] = Vector3(cap2d[i_tri+1].x, cap2d[i_tri+1].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d[i_tri+2].x, cap2d[i_tri+2].y, 0.0)
		
	return vertices


func get_in_place_transformed(
	p_vertices: PackedVector3Array,
	p_transform: Transform3D
) -> PackedVector3Array:
	for i_vertex in range(0, len(p_vertices)):
		p_vertices[i_vertex]\
		= p_transform.basis * p_vertices[i_vertex] + p_transform.origin
		
	return p_vertices


func get_mesh_instance3d_from_vertices(
	p_vertices: PackedVector3Array
) -> MeshInstance3D:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = p_vertices
	
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface_arrays
	)
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override\
	= load("res://dev/cavedig/cavedig_material.tres")
	
	return mesh_instance


func extrude_loop_to_loop(
	p_from: PackedVector3Array,
	p_to: PackedVector3Array
) -> PackedVector3Array:
	assert(len(p_from) == len(p_to))
	
	var i_next_vertex := 0
	var loop_vertex_count := len(p_from)
	var vertices := PackedVector3Array([])
	
	for i_vertex in range(0, loop_vertex_count):
		if i_vertex == loop_vertex_count - 1:
			i_next_vertex = 0
		else:
			i_next_vertex = i_vertex + 1
			
		# Tri 1
		vertices.append(p_from[i_vertex])
		vertices.append(p_to[i_vertex])
		vertices.append(p_from[i_next_vertex])
		# Tri 2
		vertices.append(p_from[i_next_vertex])
		vertices.append(p_to[i_vertex])
		vertices.append(p_to[i_next_vertex])
	return vertices


func update(p_curve: Curve3D) -> void:
	var point_loops: Array[PackedVector3Array] = []
	var vertices := PackedVector3Array()
	
	var baked_points := p_curve.get_baked_points()
	# For debug:
	#var baked_points := PackedVector3Array([
		#Vector3(0.0, 0.0, 0.0),
		#Vector3(30.0, 30.0, 30.0),
	#])
	
	# Initialize `point_loops` with loops transformed along the curve.
	for i_baked in len(baked_points):
		# var point_transform := Transform3D(transform)
		#var point_transform := Transform3D(
			#Basis(),
			#baked_points[i_baked]
		#)
		var point_transform := get_baked_point_transform(i_baked)
		var current_loop := PackedVector3Array()
		
		for vertex in profile3d:
			var transformed_vertex\
			:= point_transform.basis * vertex + point_transform.origin
			
			current_loop.append(transformed_vertex)
			# Debug: Blueish: Point
			#Cavedig.needle(self, point_transform, Vector3(0.1, 0.1, 1.0), 0.01, 0.0015)
			
		point_loops.append(current_loop)
		
		# Debug: Reddish: Curve
		#Cavedig.needle(self, point_transform, Vector3(1.0, 0.1, 0.1), 0.006, 0.002)
	
	# Debug: Reddish-long: Base points in curve.
	for i_point in curve.point_count:
		Cavedig.needle(
			self,
			Transform3D(Basis(), curve.get_point_position(i_point)),
			Vector3(1.0, 0.1, 0.1),
			1.6,
			 0.004
		)
	
	# Make first cap.
	vertices += get_in_place_transformed(
		get_cap3d(true),
		get_baked_point_transform(0)
	)
	
	# We're not doing this for the last loop, as this is expecting a "next"
	# loop in order to work - the last loop will already have been integrated
	# by the run pertaining to its previous loop, to which it will have served
	# as that "next" loop.
	for i_loop in range(0, len(point_loops) - 1):
		vertices\
		= vertices\
		+ extrude_loop_to_loop(point_loops[i_loop], point_loops[i_loop+1])
		
		#var loop := point_loops[i_loop]
		## Not doing it for the last point. Same concept as for the loops.
		#for i_point in range(0, len(loop) - 1):
			## Tri 1
			#vertices.append(point_loops[i_loop][i_point])
			#vertices.append(point_loops[i_loop+1][i_point])
			#vertices.append(point_loops[i_loop][i_point+1])
			## Tri 2
			#vertices.append(point_loops[i_loop][i_point+1])
			#vertices.append(point_loops[i_loop+1][i_point])
			#vertices.append(point_loops[i_loop+1][i_point+1])
			#i_point += 1
		#i_loop += 1
	
	# Make second cap:
	vertices += get_in_place_transformed(
		get_cap3d(false),
		get_baked_point_transform(len(baked_points)-1)
	)
		
	# Debug: Greenish: Final vertices
	var i_debug := 0
	for vertex in vertices:
		if i_debug == 0:
			Cavedig.needle(self,Transform3D(Basis(), vertex),Vector3(0.0, 1.0, 0.0), 0.13, 0.0012)
		elif i_debug == 1:
			Cavedig.needle(self,Transform3D(Basis(), vertex),Vector3(0.4, 0.6, 0.0), 0.16, 0.0010)
		elif i_debug == 2:
			Cavedig.needle(self,Transform3D(Basis(), vertex),Vector3(0.0, 0.2, 0.8), 0.19, 0.0008)
		elif i_debug == 3:
			Cavedig.needle(self,Transform3D(Basis(), vertex),Vector3(0.8, 0.2, 0.4), 0.22, 0.0006)
			
		if i_debug == 3:
			i_debug = 0
		else:
			i_debug += 1
	#var debug_overlay := MeshDebugLib.ADebugOverlay.new()
	#debug_overlay.visualize_array_vertex(vertices)
	#for vertex in vertices:
		#print(vertex)
	#add_child(debug_overlay)
	add_child(get_mesh_instance3d_from_vertices(vertices))
	#add_child(_static_cube_extrusion_experiment())

func _ready() -> void:
	
	profile2d = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.0, 0.2),
		Vector2(0.2, 0.2),
		Vector2(0.2, 0.0)
	])
	
	var point_idx := 2
	print(
		"Point: idx: %s (coords: %s), transform: %s"\
		% [
			point_idx,
			curve.get_point_position(point_idx),
			curve.sample_baked_with_rotation(curve.get_closest_offset(curve.get_point_position(point_idx)), false, true)
		]
	)
	
	update(curve)
