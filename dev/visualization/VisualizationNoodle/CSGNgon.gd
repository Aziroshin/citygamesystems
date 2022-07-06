# N-gon
# Illustration (just imagine the angles and sides being the same :p):
#  ___
# /   \
# |   |
# \___/

@tool
extends CSGPolygon3D

const DEFAULT_SIDES := 3
const DEFAULT_SIDE_SCALE := 1.0
const DEFAULT_OFFSET := Vector2(0, 1)
const DEFAULT_CENTERED := true

@export var sides := DEFAULT_SIDES:
	set(value):
		sides = value
		_update()
@export var side_scale := DEFAULT_SIDE_SCALE:
	set(value):
		side_scale = value
		_update()
@export var offset := DEFAULT_OFFSET:
	set(value):
		offset = value
		_update()
@export var centered := DEFAULT_CENTERED:
	set(value):
		centered = value
		_update()

# Returns a `PoolVector2array` of angle-adjusted basic vectors, with
# each corresponding to a vertice in an n-gon.
func ngon_vertices(n: int, side_scale: float) -> Array[Vector2]:
	if n < 3:
		return Array()
		
	var vertices: Array[Vector2] = Array([Vector2(side_scale - side_scale / 2, 0)])
	for vertex_index in range(1, n+1):
		
		# TODO: Try this formula for vector_length: 2 * sin(deg2rad(360 / 2n))
		# It just produces a line, so, we've obviously done something wrong. xD
		#var vector_length = deg2rad(360 / 2 * n)
		#var vector_length = deg2rad(90+360/n*vertex_index)
		#var vector_length = deg2rad(360.0/n*vertex_index)
		var vector_length = deg2rad(1.0)
		print("vector_length: %s, radians: %s" % [vector_length, deg2rad(vector_length)])
	
		vertices.append(Vector2(
			sin(vector_length) * side_scale/n,
			-1 * cos(vector_length) * side_scale/n
		))
		
	return vertices
	
# Takes a polygon for reference and a `Vector2` representing a vertex and
# returns the resultant of the last vertex in the polygon and the specified
# vertex. If the polygon has no vertices, the specified vertex is returned.
func new_vertex(reference_polygon: Array[Vector2], new_vector: Vector2) -> Vector2:
	var new_vector_transformed = new_vector
	if reference_polygon.size() > 0:
		new_vector_transformed = reference_polygon[-1] + new_vector
	return new_vector_transformed

# Takes a `PoolVector2Array` of vertices and returns a `PoolVector2Array`
# with each vertice added to the preceding one.
func create_resultant_polygon_from_vertices(vertices: Array[Vector2]) -> Array[Vector2]:
	var new_polygon: Array[Vector2] = Array()
	for vertex in vertices:
		new_polygon.append(new_vertex(new_polygon, vertex))
	return new_polygon

func offset_polygon(vertices: Array[Vector2], offset: Vector2) -> Array[Vector2]:
	var offset_polygon: Array[Vector2] = Array()
	for vertex in vertices:
		offset_polygon.append(vertex - offset)
	return offset_polygon
	
func _get_greatest_y(vertices: Array[Vector2]) -> float:
	assert(vertices.size() > 0, "The vertices array shouldn't be empty.")
	
	if vertices.size() == 0:
		push_error(
			"Attempted to get the greatest `y` component from an empty array of vertices. " +
			"Returning `0.0`."
		)
		return 0.0
	
	# In case all vertices are negative, we definitely don't want to initialize
	# with `0.0`, as that'd always be greater than any ys we'll find. Instead,
	# we initialize with the first y we can get from the actual data.
	var greatest_y_so_far := vertices[0].y
	# This redundantly checks against the vertice we just initialized from.
	# I'm unsure whether it's worth it to prevent it, unless there's a clever
	# way to do it that doesn't involve `vertices.size() > 1` or whatever. xD
	for vertice in vertices:
		if vertice.y > greatest_y_so_far:
			greatest_y_so_far = vertice.y
	return greatest_y_so_far
	
#func center_polygon(vertices: Array[Vector2], offset: Vector2) -> Array[Vector2]:
#	var _polygon: Array[Vector2]

func create_positive_ngon(
	n: int = DEFAULT_SIDES,
	side_scale: float = DEFAULT_SIDE_SCALE,
	offset: Vector2 = DEFAULT_OFFSET
) -> Array[Vector2]:
	var resultant_polygon: Array[Vector2] = create_resultant_polygon_from_vertices(ngon_vertices(n, side_scale))
	if not offset == Vector2(0, 0):
		return offset_polygon(resultant_polygon, offset)
	return resultant_polygon

func create_centered_ngon(
	n: int = DEFAULT_SIDES,
	side_scale: float = DEFAULT_SIDE_SCALE
) -> Array[Vector2]:
	# No offset, as we'll center it anyway.
	var ngon: Array[Vector2] = create_positive_ngon(n, side_scale, Vector2(0, 0))
	print("greatest_y: %s" % _get_greatest_y(ngon))
	return offset_polygon(ngon, Vector2(0, _get_greatest_y(ngon) / 2))

func create_ngon(
	n: int = DEFAULT_SIDES,
	side_scale: float = DEFAULT_SIDE_SCALE,
	offset: Vector2 = DEFAULT_OFFSET,
	centered: bool = DEFAULT_CENTERED
) -> Array[Vector2]:
	if centered:
		return create_centered_ngon(n, side_scale)
	return create_positive_ngon(n, side_scale, offset)

# Updates the n-gon.
func _update():
	polygon = create_ngon(sides, side_scale, offset)
	print("ngon: %s" % polygon)

func _enter_tree():
	_update()
