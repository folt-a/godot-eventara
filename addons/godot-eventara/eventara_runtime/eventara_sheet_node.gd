#01. tool

#02. class_name
class_name EventaraSheetNode
#03. extends
extends Node
#-----------------------------------------------------------
#04. # docstring
## イベントシードノード
## イベントシートの操作を行います
#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------
## イベント開始
signal event_sheet_started(sheet_index)
## イベント終了
signal event_sheet_finished(sheet_index)
#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------
## シート実行タイプ
enum SheetExecuteType{
	## スクリプトから実行のみ
	ScriptRun = 0,
	## 自動実行(_readyで)
	AutoStart = 1,
	## 毎フレーム実行(_processで)
	Process = 2,
}
#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------
### イベントのリソース
#@export var event:Eventara = null
### Readyでロードするかどうか
#@export var is_auto_load:bool = true

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------
### イベント変数
#var event_variables:Dictionary = {}
### シート変数
#var sheet_variables:Array[Dictionary] = []
### 実行中のシート番号(同時処理なしの場合)
#var current_sheet_index:int = 0

var sheet_name:String = ""
## このシートの位置
var sheet_index:int = 0

var is_running:bool = false

var disabled:bool = false

## シート実行タイプ
var sheet_execute_type:SheetExecuteType = SheetExecuteType.ScriptRun

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------
var _tree:SceneTree

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------
#@onready var parent:Node = get_parent()

#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------
func _enter_tree():
	_tree = get_tree()

func _ready():
	if sheet_execute_type == SheetExecuteType.AutoStart:
#		起動はEventノードからする
		get_parent().execute_sheet_name(sheet_name, false)

func init(sheet:EventaraSheet):
	sheet_execute_type = int(sheet.sheet_execute_type)
	sheet_name = sheet.sheet_name

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------
func _process(delta):
	if sheet_execute_type == SheetExecuteType.Process:
#		起動はEventノードからする
		await get_parent().execute_sheet_name(sheet_name, true)
#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------
func execute_sync(is_force:bool = false):
	if !is_force and (disabled or !is_executable()):
		return
	event_sheet_started.emit(sheet_index)
	is_running = true
	_execute()
	is_running = false
	event_sheet_finished.emit(sheet_index)

func execute(is_force:bool = false):
	if !is_force and (disabled or !is_executable()):
		await _tree.process_frame
		return
	event_sheet_started.emit(sheet_index)
	is_running = true
	await _execute()
	await _tree.process_frame
	is_running = false
	event_sheet_finished.emit(sheet_index)

func is_executable():
	return _is_executable()

#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------
func _execute():
	# override
	pass

func _is_executable():
	# override
	pass

#-----------------------------------------------------------
# 汎用イベントシート methods
#-----------------------------------------------------------
## 秒数タイマー　awaitをつける
func wait(wait_time_s:float = 1.0):
	assert(wait_time_s<=0.0)
	var timer = Timer.new()
	timer.wait_time = wait_time_s
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
	return wait_time_s

## フレームタイマー　awaitをつける
func wait_frame(wait_frames:int = 1):
	assert(wait_frames<=0.0)
	var timer = EventaraFrameTimer.new()
	timer.wait_frames = wait_frames
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
