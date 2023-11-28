@tool
extends Node3D

### "Imports": MeshLib
const AHorizontallyFoldedTriangle := MeshLib.AHorizontallyFoldedTriangle
const ASubdividedLine := MeshLib.ASubdividedLine
const MFlipVerticesX := MeshLib.MFlipVerticesX
const MTranslateVertices := MeshLib.MTranslateVertices
const MShearVertices := MeshLib.MShearVertices

### "Imports": MeshDebugLib
const ADebugOverlay := MeshDebugLib.ADebugOverlay

@onready var RoofDoublePitchedSide: Resource = load("res://assets/parts/roof_double_pitched_side.gltf")
@onready var RoofDoublePitchedCorner: Resource = load("res://assets/parts/roof_double_pitched_corner.gltf")
@onready var RoofDoublePitchedSideForkedGableWing: Resource = load("res://assets/parts/roof_double_pitched_forked_gable_wing.gltf")
@onready var FacadeB: Resource = load("res://assets/parts/facade_b.gltf")


func get_kinked_roof_line_arrays() -> Array:
	var vertices := CityGeoFuncs.create_kinked_roof_line(
		Vector3(),
		Vector3(0, 1, -1),
		4
	)
	var normals := PackedVector3Array()
	var tex_uv := PackedVector2Array()
	var last_vertex := vertices[len(vertices)-1]
	for idx in len(vertices):
		# Normals pointing up - can be recalculated to roof slope later.
		normals.append(Vector3(0, 1, 0))
		
		var u: float = last_vertex.x / vertices[idx].x
		var v: float = 1.0
		tex_uv.append(Vector2(u,v))
		
	var arrays := Array([])
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = tex_uv
	return arrays

func _mess_AHorizontallyFoldedTriangle(p_show_debug_overlay := false) -> Node3D:
	var mess_node := Node3D.new()
		
	var kinked_roof_line := get_kinked_roof_line_arrays()
	var tri_left_side := ASubdividedLine.new(
		kinked_roof_line[ArrayMesh.ARRAY_VERTEX],
		kinked_roof_line[ArrayMesh.ARRAY_NORMAL],
		kinked_roof_line[ArrayMesh.ARRAY_TEX_UV]
	)
	tri_left_side.add_modifier(MShearVertices.new(0.5, Vector3(1, 0, 0)))
	tri_left_side.apply_all()
	
	var tri_right_side := tri_left_side.copy_as_ASubdividedLine()
	tri_right_side.add_modifier(MFlipVerticesX.new())
	tri_right_side.add_modifier(MTranslateVertices.new(Vector3(1, 0, 0)))
	tri_right_side.apply_all()
		
	var folded_triangle := AHorizontallyFoldedTriangle.new(
		tri_left_side.get_array_vertex(),
		tri_right_side.get_array_vertex()
	)
	var folded_triangle2 := AHorizontallyFoldedTriangle.new(
		tri_left_side.get_array_vertex(),
		tri_right_side.get_array_vertex()
	)
	folded_triangle2.offset = Transform3D(Basis(), folded_triangle2.tip_tri.top.untransformed).rotated_local(Vector3(1, 0, 0), PI/2)
	folded_triangle.apply_all()
	folded_triangle2.apply_all()
	
	# Folded Triangle 1
	var tri_surface_arrays := []
	tri_surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	var tri_surface_array_vertex := folded_triangle.get_array_vertex()
	tri_surface_arrays[ArrayMesh.ARRAY_VERTEX] = tri_surface_array_vertex
	
	# Folded Triangle 2
	var tri2_surface_arrays := []
	tri2_surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	var tri2_surface_array_vertex := folded_triangle2.get_array_vertex()
	tri2_surface_arrays[ArrayMesh.ARRAY_VERTEX] = tri2_surface_array_vertex
	
	var tri_node := CityGeoFuncs.get_array_mesh_node(tri_surface_arrays)
	var tri2_node := CityGeoFuncs.get_array_mesh_node(tri2_surface_arrays)
	
	mess_node.add_child(tri_node)
	mess_node.add_child(tri2_node)
	if p_show_debug_overlay:
		mess_node.add_child(ADebugOverlay.new().visualize_arrays(tri_surface_arrays))
	return mess_node
	
	
func _ready() -> void:
	add_child(_mess_AHorizontallyFoldedTriangle(true))
