extends Node3D

@onready var curve_rigs: Array[Node2D] = [
	$Node2D/PointyHorseshoeCurve
]


func _ready() -> void:
	for rig in curve_rigs:
		var visualizer := Curve2DDebugVisualizer.new()
		visualizer.curve = rig.get_node("Path2D").curve
		rig.add_child(visualizer)
