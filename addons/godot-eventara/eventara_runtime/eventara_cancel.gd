extends RefCounted

class_name EventaraCancel

var callable:Callable
var is_canceled:bool = false

func _init(_callable:Callable):
	self.callable = _callable

func execute():
	if is_canceled:
		callable.call()
	pass
