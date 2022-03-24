# N-gon resting on its "bottom" edge.
# Illustration (just imagine the angles and sides being the same :p):
#  ___
# /   \
# |   |
# \___/

tool
extends CSGPolygon

export var sides := 3

# Returns a `PoolVector2array` of angle-adjusted basic vectors, with
# each corresponding to a vertice in an n-gon.
func ngon_vertices(n: int) -> PoolVector2Array:
	if n < 3:
		return PoolVector2Array()
		
	var vertices := PoolVector2Array([Vector2(0.5, 0)])
	for vertex_index in range(1, n+1):
		var side_vector = deg2rad(90+360/n*vertex_index)
		vertices.append(Vector2(sin(side_vector), -1 * cos(side_vector)))
	return vertices
	
# Takes a a polygon for reference and a `Vector2` representing a vertex and
# returns the resultant of the last vertex in the polygon and the specified
# vertex. If the polygon has no vertices, the specified vertex is returned.
func new_vertex(reference_polygon: PoolVector2Array, new_vector: Vector2) -> Vector2:
	var new_vector_transformed = new_vector
	if reference_polygon.size() > 0:
		new_vector_transformed = reference_polygon[-1] + new_vector
	return new_vector_transformed

# Takes a `PoolVector2Array` of vertices and returns a `PoolVector2Array`
# with each vertice added to the preceding one.
func create_resultant_polygon_from_vertices(vertices: PoolVector2Array) -> PoolVector2Array:
	var new_polygon := PoolVector2Array()
	for vertex in vertices:
		new_polygon.append(new_vertex(new_polygon, vertex))
	return new_polygon

func create_ngon(n: int) -> PoolVector2Array:
	return create_resultant_polygon_from_vertices(ngon_vertices(n))
	
func _enter_tree():
	polygon = create_ngon(sides)
