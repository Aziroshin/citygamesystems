## Buffers signal calls and makes them available for subsequent re-emitting.
extends RefCounted
class_name SignalBuffer

var _calls: Array[SignalBufferCall]


func push(
	p_call: SignalBufferCall,
	p_signal_receiver_method: Callable
) -> void:
	p_call.signal_receiver_method = p_signal_receiver_method
	_calls.append(p_call)


func pop() -> SignalBufferCall:
	return _calls.pop_back()


## Batch-emit all buffered calls.
func flush() -> void:
	for i_call in len(_calls):
		pop().flush()
