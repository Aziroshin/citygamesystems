extends Node

@onready var map: PlaneMap = $Map


func _ready() -> void:
	var transform_visualizer: CavedigTransform3DVisualizer = CavedigTransform3DVisualizer.new(
		map,
		Color(0.4, 1.0, 1.0),
		Vector3(3.0, 3.0, 3.0),
		Vector3(0.2, 0.2, 0.2)
	)
	var direction := Vector3(1.3, 3.4, 2.8)
	Cavedig.needle(map, Transform3D(Basis(), -direction))
	transform_visualizer.add_array(
		[
			Transform3D(Basis.looking_at(direction), Vector3(0.0, 0.0, 0.0)),
			Transform3D(Basis(), Vector3(1.0, 1.5, 0.0)),
			Transform3D(Basis(), Vector3(0.0, 1.7, 0.4))
		],
		[
			Vector3(2.0, 5.0, 6.0),
			Vector3(0.5, 0.2, 0.7)
		],
		[
			Vector3(0.2, 2.0, 1.3),
			Vector3(2.0, 2.0, 2.0)
		]
	)
	
	transform_visualizer.bake()
	#transform_visualizer.reset()
	#transform_visualizer.add(Transform3D(Basis.looking_at(direction), Vector3(0.0, 0.0, 0.0)))
	#transform_visualizer.add(Transform3D(Basis(), Vector3(1.0, 1.5, 0.0)))
	#transform_visualizer.add(Transform3D(Basis(), Vector3(0.0, 1.7, 0.4)))
	#transform_visualizer.bake()
