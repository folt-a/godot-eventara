#01. tool
@tool
#02. class_name
class_name Eventara
#03. extends
extends Resource
#-----------------------------------------------------------
#04. # docstring
## イベントのリソースです。
## イベントの設定や、イベントシートのリソースをセットします。
#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------

#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------
## 複数シート同時処理設定
enum EventExecuteParallel{
	SINGLE = 0,
	PARALLEL = 1,
}
#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------
## ID
@export var id:StringName = &""
## 実行スクリプト[]
@export var sheets:Array[EventaraSheet] = []
## 複数シート同時処理設定
@export var event_execute_parallel:EventExecuteParallel = 0

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------
func _init():
#	resource_local_to_scene = true
#	setup_local_to_scene_requested.connect(_ready)
	pass

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------
func _ready():
	pass
#	for sheet_script in sheet_scripts:
#		var expression = Expression.new()
#		var error = expression.parse(sheet_script)
#		if error != OK:
#			printerr(expression.get_error_text())
#			continue
#		sheet_script_expressions.append(expression)
#	for sheet_condition in sheet_conditions:
#		var expression = Expression.new()
#		var error = expression.parse(sheet_condition)
#		if error != OK:
#			printerr(expression.get_error_text())
#			continue
#		sheet_condition_expressions.append(expression)
#		var result = expression.execute()
#		if not expression.has_execute_failed():
#			$LineEdit.text = str(result)

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------

#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------


#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------

