# N-gon
# Illustration (just imagine the angles and sides being the same :p):
#  ___
# /   \
# |   |
# \___/

@tool
extends CSGPolygon3D

const DEFAULT_SIDES := 3
const DEFAULT_CIRCUMRADIUS := 1.0
const DEFAULT_OFFSET := Vector2(0, 0)

@export var sides := DEFAULT_SIDES:
	set(value):
		sides = value
		_update()
@export var circumradius := DEFAULT_CIRCUMRADIUS:
	set(value):
		circumradius = value
		_update()
@export var offset := DEFAULT_OFFSET:
	set(value):
		offset = value
		_update()

# Returns an array with one vector per vertex in a 2D n-gon,
# whereas each vector points from Vector2(0, 0) to the origin
# of the vertex, thus describing the n-gon.
func ngon_vertices(n: int, circumradius: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = Array()
	if n < 3:
		return vertices
		
	var rad_per_n = 2*PI/n
	
	for vertex_index in range(0, n):
		vertices.append(Vector2(
			sin(rad_per_n * vertex_index) * circumradius,
			cos(rad_per_n * vertex_index) * circumradius
		))
	return vertices

func offset_polygon(vertices: Array[Vector2], offset: Vector2) -> Array[Vector2]:
	var offset_polygon: Array[Vector2] = Array()
	for vertex in vertices:
		offset_polygon.append(vertex - offset)
	return offset_polygon

func create_ngon(
	n: int = DEFAULT_SIDES,
	circumradius: float = DEFAULT_CIRCUMRADIUS,
	offset: Vector2 = DEFAULT_OFFSET,
) -> Array[Vector2]:
	return offset_polygon(ngon_vertices(n, circumradius), offset)

# Updates the n-gon.
func _update():
	polygon = create_ngon(sides, circumradius, offset)

func _enter_tree():
	_update()
