extends Resource

class_name EventaraCommandBase

signal command_started
signal command_ended

@export var args:Array = []

func execute():
	command_started.emit()
	_execute.call()
	command_ended.emit()


## for override
func _execute():
#	for override
	pass
