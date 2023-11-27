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
func ngon_vertices(p_n: int, p_circumradius: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	if p_n < 3:
		return vertices
		
	var rad_per_n = 2*PI/p_n
	
	for vertex_index in range(0, p_n):
		vertices.append(Vector2(
			sin(rad_per_n * vertex_index) * p_circumradius,
			cos(rad_per_n * vertex_index) * p_circumradius
		))
	return vertices

func offset_polygon(p_vertices: Array[Vector2], p_offset: Vector2) -> Array[Vector2]:
	var polygon_verts: Array[Vector2] = []
	for vertex in p_vertices:
		polygon_verts.append(vertex - p_offset)
	return polygon_verts

func create_ngon(
	p_n: int = DEFAULT_SIDES,
	p_circumradius: float = DEFAULT_CIRCUMRADIUS,
	p_offset: Vector2 = DEFAULT_OFFSET,
) -> Array[Vector2]:
	return offset_polygon(ngon_vertices(p_n, p_circumradius), p_offset)

# Updates the n-gon.
func _update():
	polygon = create_ngon(sides, circumradius, offset)

func _enter_tree():
	_update()
