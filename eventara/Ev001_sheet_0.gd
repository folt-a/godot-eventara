extends EventaraSheetNode
@onready var ev:EventaraNode = get_parent()
@onready var n:Node = ev.get_parent() ## 型指定するとよい

## 実行条件判定関数
func _is_executable() -> bool:
	return true

##
func _execute() -> String:
	print("TEST1")
	return  "TEST1"
