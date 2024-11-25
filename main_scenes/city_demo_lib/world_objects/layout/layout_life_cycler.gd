extends CityGameWorldObjectLifeCycler
class_name LayoutWorldObjectLifeCycler

# Dependencies:
# - CityBuilder.Layout

func create(
	p_outline_points: PackedVector3Array,
	p_corner_indexes: PackedInt64Array,
	p_distal_outline_offset_magnitude := 1.0,
	p_distal_outline_offset_direction := Vector3.UP
) -> LayoutWorldObject:
	var layout := CityBuilder.Layout.new(
		p_outline_points,
		p_corner_indexes,
	)
	return create_from_layout(layout)


func create_from_corner_points(p_corner_points: PackedVector3Array) -> LayoutWorldObject:
	return create_from_layout(CityBuilder.Layout.new(
		p_corner_points,
		PackedInt64Array(range(len(p_corner_points)))
	))


# I'm not yet sure where to put the create-collider stuff, so I'm putting
# it here for now.
func _create_collider(
	p_layout: CityBuilder.Layout,
	p_depth := 1.0
) -> CollisionObject3D:
	var collider := WorldObjectArea3D.new()
	var shape := CollisionPolygon3D.new()
	var shape_polygon_vertices = PackedVector2Array()
	var triangulated_shape_indexes := PackedInt32Array()
	var shape_vertices := PackedVector2Array()
	
	for corner_point in p_layout.corner_points:
		shape_polygon_vertices.append(Vector2(corner_point.x, corner_point.z))
	#triangulated_shape_indexes = Geometry2D.triangulate_delaunay(shape_polygon_vertices)
	#print(len(triangulated_shape_indexes))
	
	#var vert_idx = 0
	#for idx in triangulated_shape_indexes:
		#shape_vertices.append(shape_polygon_vertices[idx])
		#Cavedig.needle(
			#collider,
			#Transform3D(
				#Basis(),
				#Vector3(
					#shape_polygon_vertices[idx].x,
					#2.0,
					#shape_polygon_vertices[idx].y
				#)
			#),
			#Vector3(0.0, 0.8, 0.1),
			#1.0-0.05*vert_idx,
			#0.15+0.055*vert_idx
		#)
		#vert_idx += 1
		
	shape.transform = shape.transform.rotated(Vector3(1.0, 0.0, 0.0), PI/2)
	shape.depth = p_depth
	shape.polygon = shape_polygon_vertices
	collider.add_child(shape)
	
	return collider


func create_from_layout(p_layout: CityBuilder.Layout) -> LayoutWorldObject:
	var world_object := LayoutWorldObject.new()
	world_object.layout = p_layout
	world_object.add_collider(_create_collider(world_object.layout))
	
	return world_object
