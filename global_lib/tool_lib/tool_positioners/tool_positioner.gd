extends Node
class_name ToolLibToolPositioner


## Used to carry the information whether an attempt to get a position succeeded.
class PositionGettingStatus:
	var got_position := false


func _ready() -> void:
	pass


## Get a position that corresponds to the specified reference position.
## 
## A `PositionGettingStatus` object can be passed which will have information
## on whether the attempt to get a position succeeded or not. If its
## `.got_position` property is `true`, a position could be determined.
## This is useful for cases where multiple positioners are involved, and
## a decision has to be made about which ones actually have a meaningful
## position to offer, and which ones just returned some kind of default
## position.
## This is of particular interest if the reference position and the returned
## position are the same: That might just be the default behaviour, or it might
## be the coincidental result of a legitimate determination of the position.
func get_position(
	p_reference_position: Vector3,
	_p_status := PositionGettingStatus.new()
) -> Vector3:
	return p_reference_position
