extends Node3D

@onready var map := $Map


#enum {}

#class PathNodeNetworkGroupNetwork:
#	var name
#	func _init(name):
#		self.name = name
#
#class PathNodeNetworkGroup:
#	var networks = []
#	func _init(networks):
#		for network in networks:
#			self.networks.append(PathNodeNetworkGroupNetwork.new(name))

class PathNode:
	var neighbours = []
	func _addNeighbour(pathNode):
		self.neighbours.append(pathNode)
		return self
	func connectWithNeighbour(pathNode):
		self._addNeighbour(pathNode)
		pathNode._addNeighbour(self)
		return self
	func getNeighbours():
		return self.neighbours
		
class PathNodePathFindState:
	pass
		

class PathNodePath:
	var startNode
	var endNode
	var nodes = []
	func _init(startNode, endNode):
		self.startNode = startNode
		self.endNode = endNode
	func find():
		var currentNode = self.startNode
		var endNodeFound = false
		while !endNodeFound:
			if currentNode == self.endNode:
				endNodeFound = true
		return self
	
class Entity:
	var pathNodes = []
	func addPathNode(pathNode):
		self.pathNodes.append(pathNode)
		return self
		
func _ready():
	
	assert(Visualization.OctagonMarker.instantiate()\
		.add_as_child_to(map)\
		.position_at(Vector3(2, 1, -2))\
		.set_size(0.5)\
		.primary.set_color(Vector3(0.2, 0.1, 0.6))\
		.secondary.set_color(Vector3(0.2, 0.1, 0.3))\
		.noodle_to(Visualization.OctagonMarker.instantiate()\
			.add_as_child_to(map)\
			.position_at(Vector3(3.5, 1, -2.5))\
			.set_size(0.5)\
			.primary.set_color(Vector3(0.6, 0.1, 0.4))\
			.secondary.set_color(Vector3(0.6, 0.1, 0.2))\
		)\
	)
	
#######################################################################
# Testing OctagonMarker.
#	var marker_a = Visualization.OctagonMarker.instance()\
#		.set_description("Root: Testvisualizer A")\
#		.primary.set_color(Vector3(0.2, 0.8, 0.3))\
#		.secondary.set_color(Vector3(0.8, 0.2, 0.8))\
#		.add_as_child(self)
#	marker_a.translate(Vector3(-1, -1, 0))
#
#	var marker_b = marker_a.new_knockoff()\
#		.add_as_child(self)\
#		.set_description("Root: Testvisualizer B")
#	marker_b.translate(Vector3(0, 1, 1.5))
#
#	var marker_c = marker_b.new_knockoff()\
#		.add_as_child(self)\
#		.set_description("Root: Testvisualizer C")\
#		.primary.set_color(Vector3(0.9, 0.5, 0.3))
#	marker_c.translate(Vector3(0, 1, 1.5))
	
	#######################################################################
	# Beginning of path experiments/testing.
	var pathNodeA = PathNode.new()
	var pathNodeB = PathNode.new().connectWithNeighbour(pathNodeA)
	var pathNodeC = PathNode.new().connectWithNeighbour(pathNodeB)
	var pathNodeD = PathNode.new().connectWithNeighbour(pathNodeC)
	var pathNodeE = PathNode.new().connectWithNeighbour(pathNodeD)
	var entityB = Entity.new().addPathNode(pathNodeB)
	var entityD = Entity.new().addPathNode(pathNodeD)
	
	
func _on_map_input_event(
	camera: Node,
	event: InputEvent,
	position: Vector3,
	normal: Vector3,
	shape_idx: int
) -> void:
	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT and event.pressed:
		assert(Visualization.OctagonMarker.instantiate()\
			.add_as_child_to(self)\
			.position_at(position)\
			.align_along(normal)\
			.set_size(0.2)\
			.primary.set_color(Vector3(0.2, 0.7, 0.2))\
			.secondary.set_color(Vector3(0.4, 1, 0.4))\
		)
