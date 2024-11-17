extends Node
class_name Mouse3DRayRayCaster

## If false, no raycasting will be performed.
@export var enabled := true
## The `Mouse3DRay` we're raycasting for.
@export var mouse_3d_ray: Mouse3DRay
## Emitted whenever ray casting data is updated.
signal updated
