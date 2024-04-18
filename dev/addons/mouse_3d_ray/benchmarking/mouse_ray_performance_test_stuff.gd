## Parent to something that shows up in the world to get some
## stacked collision meshes for mouse ray performance testing.
extends Node3D


func create_collider(p_points: PackedVector3Array, p_depth := 3.0) -> CollisionObject3D:
	var collider := Area3D.new()
	var shape := CollisionPolygon3D.new()
	var shape_polygon_vertices = PackedVector2Array()
	var triangulated_shape_indexes := PackedInt32Array()
	var shape_vertices := PackedVector2Array()
	
	for corner_point in p_points:
		shape_polygon_vertices.append(Vector2(corner_point.x, corner_point.z))

	shape.transform = shape.transform.rotated(Vector3(1.0, 0.0, 0.0), PI/2)
	 
	shape.depth = p_depth
	shape.polygon = shape_polygon_vertices
	collider.add_child(shape)
	return collider


func _ready() -> void:
	var points_quarter := PackedVector3Array([
		Vector3(0.19509, 0.0, 0.980785),
		Vector3(0.382683, 0.0, 0.92388),
		Vector3(0.55557, 0.0, 0.83147),
		Vector3(0.707107, 0.0, 0.707107),
		Vector3(0.83147, 0.0, 0.55557),
		Vector3(0.92388, 0.0, 0.382683),
		Vector3(0.980785, 0.0, 0.19509),
	])
	var points := PackedVector3Array()
	for i in range(len(points_quarter)):
		points.append(-points_quarter[i])
	points += points_quarter
	
	for i in range(len(points)):
		points[i] = points[i] * 10.0
		points[i] = Vector3(points[i].x, 2.5, points[i].z)
		
	for i in range(100):
		add_child(create_collider(points))
	
	for point in points:
		Cavedig.needle(
			self,
			Transform3D(Basis(), point),
			Vector3(1.0, 1.0, 1.0)
		)
