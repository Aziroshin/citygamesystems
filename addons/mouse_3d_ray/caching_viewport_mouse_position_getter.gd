## Caches the mouse position of a viewport for a frame.
## Specifically, this caches the return value
## of `viewport.get_mouse_position()` when the value of the `.position` property
## is read. Any subsequent read access of that property will return the
## cached position for that frame.
##
## The reasoning for this is performance: `Viewport.get_mouse_position()` is an
## expensive method. This node allows many different places in the code to
## access the mouse position of a viewport in a given frame at a tiny fraction
## of that performance cost.
##
## Instances of this can also be constructed using `.new(your_viewport)`.
extends Node
class_name CachingViewportMousePositionGetter

## The viewport to cache the mouse position of.
## If this is found not to be set in `_ready`, an error will be pushed.
@export var viewport: Viewport
var _cached_position: Vector2
var _cache_frame: int
## Provides the viewport's mouse position. The first read access in a frame will
## call, cache and return the value of `viewport.get_mouse_position()`. All
## subsequent read accesses will return the cached value.
var position: Vector2:
	get:
		var current_frame := Engine.get_process_frames()
		if not _cache_frame == current_frame:
			_cached_position = viewport.get_mouse_position()
			_cache_frame = current_frame
		return _cached_position


func _init(p_viewport: Viewport):
	viewport = p_viewport


func _ready() -> void:
	if not viewport:
		var error_message := "%s doesn't have a viewport specified." % get_name()
		push_error(error_message)
		assert(viewport, error_message)
