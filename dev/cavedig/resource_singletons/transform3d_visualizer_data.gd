## Predominantly designed to serve as a "global" data store for Transform3D
## visualizers spawned by `Cavedig.transform_3d` and the like.
##
## The globalness of this isn't enforced or relied on, so, in theory, it'd
## be possible to have multiple resource-instances of this.
extends Resource
class_name CavedigTransform3DVisualizerData

## Holds visualizers referenced by a `StringName` handle.
## This enables conveniently grouping visualizers by handle in various code
## locations.
var visualizers_by_handle: Dictionary[StringName, CavedigTransform3DVisualizer]
## A globally shared visualizer which can be used as a default when no handle
## has been specified.
var global_visualizer: CavedigTransform3DVisualizer


func reset_visualizers_by_handle() -> void:
	for handle in visualizers_by_handle.keys():
		visualizers_by_handle[handle].reset()


func reset_global_and_visualizers_by_handle() -> void:
	reset_visualizers_by_handle()
	global_visualizer.reset()
