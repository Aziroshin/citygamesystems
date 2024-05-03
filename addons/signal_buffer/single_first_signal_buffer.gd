## A `SignalBuffer` that only holds one call and only accepts a push if its
## number of buffered calls is zero.
extends SignalBuffer
class_name SingleFirstSignalBuffer


func push(
	p_call: SignalBufferCall,
	p_signal_receiver_method: Callable
) -> void:
	p_call.signal_receiver_method = p_signal_receiver_method
	if len(_calls) == 0:
		_calls.append(p_call)
