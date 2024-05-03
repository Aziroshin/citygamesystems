## Represents a signal call in the context of a `SignalBuffer`.
extends RefCounted
class_name SignalBufferCall

var signal_receiver_method: Callable


## Override and `super()` sub-class.
func flush() -> void:
	pass
