extends RefCounted
class_name MeshDebugLib

class ADebugOverlay extends Node3D:
	var default_font_size := 8
	
	func set_default_font_size(new_default_font_size: int) -> ADebugOverlay:
		default_font_size = new_default_font_size
		return self
	
	func add_label(
		title: String,
		xyz: Vector3,
		label_specific_font_size := -1
	) -> ADebugOverlay:
		var label := Label3D.new()
		label.translate(xyz)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.text = "%s: %s" % [title, xyz]
		label.fixed_size = true
		if label_specific_font_size >= 0:
			label.font_size = label_specific_font_size
		else:
			label.font_size = default_font_size
		
		add_child(label)
		return self
		
	func visualize_arrays(arrays: Array) -> ADebugOverlay:
		var idx := 0
		for xyz in arrays[ArrayMesh.ARRAY_VERTEX]:
			add_label("%s" % idx, xyz)
			idx += idx
		return self
		
	func visualize_array_vertex(
		array_vertex: PackedVector3Array
	) -> ADebugOverlay:
		var surface_arrays := []
		surface_arrays.resize(ArrayMesh.ARRAY_MAX)
		surface_arrays[ArrayMesh.ARRAY_VERTEX] = array_vertex
		visualize_arrays(surface_arrays)
		return self
		
		
#class ADebugOverlay2D extends Sprite3D:
#	var viewport := SubViewport.new()
#
#	func _init():
#		self.billboard = BaseMaterial3D.BILLBOARD_ENABLED
#		add_child(viewport)
#
#	func _on_process(delta: float) -> void:
#		#viewport.size = 
#		pass
#
#	func add_label(title: String, xyz: Vector3) -> ADebugOverlay2D:
#		var label := Label.new()
#		label.translate(xyz)
#		label.text = "%s: %s" % [title, xyz]
#		label.font_size = 6
#		label.fixed_size = true
#		return self
#
#	func visualize_arrays(arrays: Array) -> ADebugOverlay2D: 
#		var idx := 0
#		for xyz in arrays[ArrayMesh.ARRAY_VERTEX]:
#			add_label("%s" % idx, xyz)
#			idx += idx
#		return self
