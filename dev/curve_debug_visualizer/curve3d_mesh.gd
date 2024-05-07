extends MeshInstance3D
class_name Curve3DDebugMesh

### Dependencies:
# - Curve3DDebugFuncs

const default_curve_material := preload("./curve_material.tres")
# 3D version of `profile2d`. Set when `profile2d` is set. Treat as readonly.
var profile3d_ro := PackedVector3Array()
# Triangulated 2D version of the cap. Set when `profil2d` is set.
# Treat as readonly.
var cap2d_ro := PackedVector2Array()
# The polygon which will be extruded along the curve. If left empty,
# it will default to a quad with a side length of 0.1.
@export var profile2d := PackedVector2Array():
	set(p_new_profile2d):
		profile2d = p_new_profile2d
		
		profile3d_ro = PackedVector3Array()
		for vertex2d in p_new_profile2d:
			profile3d_ro.append(Vector3(vertex2d.x, vertex2d.y, 0.0))
		
		cap2d_ro = PackedVector2Array()
		for idx in Geometry2D.triangulate_polygon(p_new_profile2d):
			cap2d_ro.append(p_new_profile2d[idx])
# Material for the curve mesh.
@export var material := default_curve_material.duplicate()
# Curve to use for the mesh.
# NOTE: This curve will be overwritten by the curve passed to `.update`, so,
# depending on what you do, setting the curve here might not do anything.
# The first call to `.update` in `._ready` will use this curve, however. Thus
# if there isn't anything else calling `.update`, it should be using the curve
# set here.
@export var curve := Curve3D.new()


func get_cap3d(p_inverted: bool) -> PackedVector3Array:
	assert(len(cap2d_ro) % 3 == 0)
	
	var vertices := PackedVector3Array()
	vertices.resize(len(cap2d_ro))
	
	for i_tri in range(0, len(cap2d_ro), 3):
		vertices[i_tri] = Vector3(cap2d_ro[i_tri].x, cap2d_ro[i_tri].y, 0.0)
		if p_inverted:
			vertices[i_tri+1] = Vector3(cap2d_ro[i_tri+2].x, cap2d_ro[i_tri+2].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d_ro[i_tri+1].x, cap2d_ro[i_tri+1].y, 0.0)
		else:
			vertices[i_tri+1] = Vector3(cap2d_ro[i_tri+1].x, cap2d_ro[i_tri+1].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d_ro[i_tri+2].x, cap2d_ro[i_tri+2].y, 0.0)
		
	return vertices


func _update_from_vertices(
	p_vertices: PackedVector3Array
) -> void:
	if len(p_vertices) < 3:
		mesh = ArrayMesh.new()
		return
	
	mesh = Curve3DDebugFuncs.create_array_mesh(p_vertices)
	mesh.surface_set_material(0, material)


func update() -> void:
	if curve.point_count < 2:
		_update_from_vertices(PackedVector3Array())
		return
	
	var point_loops: Array[PackedVector3Array] = []
	var vertices := PackedVector3Array()
	var baked_points := curve.get_baked_points()
	
	# Initialize `point_loops` with loops transformed along the curve.
	for i_baked in len(baked_points):
		var current_loop := PackedVector3Array()
		var point_transform := Curve3DDebugFuncs.get_baked_point_transform(curve, i_baked)
		
		for vertex in profile3d_ro:
			var transformed_vertex := point_transform.basis * vertex + point_transform.origin
			current_loop.append(transformed_vertex)
			
		point_loops.append(current_loop)
	
	# Make first cap.
	vertices += Curve3DDebugFuncs.to_transformed(
		get_cap3d(true),
		Curve3DDebugFuncs.get_baked_point_transform(curve, 0)
	)
	
	# We're skipping the last loop, as this is expecting a "next"
	# loop in order to work - the last loop will already have been integrated
	# by the iteration pertaining to its previous loop.
	for i_loop in len(point_loops) - 1:
		vertices = vertices + Curve3DDebugFuncs.get_loop_to_loop_extruded(
			point_loops[i_loop],
			point_loops[i_loop+1]
		)
	
	# Make second cap:
	vertices += Curve3DDebugFuncs.to_transformed(
		get_cap3d(false),
		Curve3DDebugFuncs.get_baked_point_transform(curve, len(baked_points)-1)
	)
	#Curve3DDebugFuncs.translate(vertices, transform.origin)
	#Curve3DDebugFuncs.localize_to_node(vertices, self)
	
	#for i_vertex in len(vertices):
		#vertices[i_vertex] = vertices[i_vertex] - global_transform.origin
	
	_update_from_vertices(vertices)


func update_from_curve(p_curve: Curve3D) -> void:
	curve = p_curve
	update()


func _ready() -> void:
	if len(profile2d) == 0:
		profile2d = PackedVector2Array([
			Vector2(0.1, 0.1),
			Vector2(0.1, -0.1),
			Vector2(-0.1, -0.1),
			Vector2(-0.1, 0.1)
		])
	update()
