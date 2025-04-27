extends Node2D

@onready var path := $Path2D
@onready var visualizer: Curve2dDebugVisualizer = $Node2D/Curve2dDebugVisualizer
@onready var viewport_texture_display: TextureRect= $TextureRect

@onready var node2d := $Node2D


func _ready() -> void:
	visualizer.curve = path.curve


func _process(_p_delta: float) -> void:
	pass
 
