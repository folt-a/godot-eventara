#01. tool

#02. class_name
class_name EventaraNode
#03. extends
extends Node
#-----------------------------------------------------------
#04. # docstring
## イベントノード
## ノードとしてイベントの操作を行います
#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------
## イベント開始
signal event_started

## イベント終了
signal event_finished

signal sheets_loaded
#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------

#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------
## イベントのリソース
@export var event:Eventara = null
## Readyでロードするかどうか
#@export var is_auto_load:bool = true

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------
## イベント変数
var event_variables:Dictionary = {}
## 実行中のシート番号(同時処理なしの場合)
var current_sheet_index:int = -1

var event_id:StringName

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------
var threads:Array[Thread] = []
var mutex = Mutex.new()
var mutex_count:int = 0

var sheets:Array[EventaraSheetNode]

var is_this_frame_running:bool = false

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------
@onready var parent:Node = get_parent()

#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------

func _ready():
	assert(event != null)
	child_entered_tree.connect(_on_child_entered_tree)
	load_event()
#	if OS.is_debug_build():
#		pass

func load_event():
	sheets = []
	for sheet in event.sheets:
		var sheet_node:EventaraSheetNode = _load_script(sheet)
		add_child(sheet_node)

func load_event_multi():
	var time_started = Time.get_ticks_msec()
	var index:int = 0
	for sheet in event.sheets:
		var thread = Thread.new()
		thread.start(_load_script_multi.bind(sheet,index))
		threads.append(thread)
		index += 1
	await sheets_loaded

func _load_script(sheet:EventaraSheet) -> EventaraSheetNode:
	var sheet_node:EventaraSheetNode = sheet.sheet_script.new()
	sheet_node.name = sheet.sheet_name
	sheets.append(sheet_node)
	sheet_node.init(sheet)
	return sheet_node

func _load_script_multi(sheet_script, thread_index):
	var sheet = _load_script(sheet_script)
	mutex.lock()
	add_child(sheet)
	mutex.unlock()
	threads[thread_index].wait_to_finish.call_deferred()

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------
func _enter_tree():
	if !Engine.is_editor_hint():
		event_id = event.id
		Evs.add_event_node(self)

func _exit_tree():
	if !Engine.is_editor_hint():
		Evs.remove_event_node(self)

func _on_child_entered_tree(node: Node):
#	print(get_child_count(), " ", event.sheets.size())
	if get_child_count() == event.sheets.size():
		sheets_loaded.emit()

#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------

## イベントを強制実行します。
func execute_sync(index = 0):
	assert(event != null)
	assert(range(sheets.size()).has(index))
	sheets[index].execute_sync()

## 現在のイベントを強制実行します。
func execute_current_sync():
	execute_sync(current_sheet_index)

## シート名を指定してイベントを強制実行します。
func execute_sheet_name_sync(sheet_name:String):
	sheets.filter(func(sheet):sheet.sheet_name == sheet_name)
	for sheet in sheets:
		if sheet.sheet_name == sheet_name:
			sheet.execute_sync()

## イベントを実行します。条件判定でfalseなら実行しません。
func execute_sync_if_condition(index = 0):
	assert(event != null)
	assert(range(sheets.size()).has(index))
	if sheets[index].is_executable():
		sheets[index].execute_sync()

## 現在のイベントを実行します。条件判定でfalseなら実行しません。
func execute_sync_current_if_condition():
	execute_if_condition(current_sheet_index)

## シート名を指定してイベントを実行します。条件判定でfalseなら実行しません。
func execute_sheet_name_sync_if_condition(sheet_name:String):
	sheets.filter(func(sheet):sheet.sheet_name == sheet_name)
	for sheet in sheets:
		if sheet.sheet_name == sheet_name:
			sheet.execute()


## イベントを実行します。
## 引数[index]指定なしならシート順に判定していき、最初のtrueのものを実行します。
func execute(index:int = -1, is_force:bool = false):
	assert(event != null)
	if index == -1:
		for sheet_node in sheets:
			if sheet_node.is_executable():
				await _execute_sheet(sheet_node,is_force)
				return
	else:
		assert(sheets.size() > index)
		await _execute_sheet(sheets[index],is_force)

## 現在のイベントを実行します。
func execute_current(is_force:bool = false):
	await execute(current_sheet_index, is_force)

## シート名を指定してイベントを実行します。
func execute_sheet_name(sheet_name:String, is_force:bool = false):
	for sheet in sheets:
		if sheet.sheet_name == sheet_name:
			await _execute_sheet(sheet,is_force)
			return

## イベントを実行します。条件判定でfalseなら実行しません。
func execute_if_condition(index:int = 0, is_force:bool = false):
	assert(event != null)
	assert(range(sheets.size()).has(index))
	await _execute_sheet(sheets[index],is_force)

## 現在のイベントを実行します。条件判定でfalseなら実行しません。
func execute_current_if_condition(is_force:bool = false):
	await execute_if_condition(current_sheet_index, is_force)

## シート名を指定してイベントを実行します。条件判定でfalseなら実行しません。
func execute_sheet_name_if_condition(sheet_name:String, is_force:bool = false):
	sheets.filter(func(sheet):sheet.sheet_name == sheet_name)
	for sheet in sheets:
		if sheet.sheet_name == sheet_name:
			await _execute_sheet(sheet,is_force)

func remove_sheet_name(sheet_name:String):
	var index:int = 0
	for sheet in sheets:
		if sheet.sheet_name == sheet_name:
			sheets.remove_at(index)
			sheet.queue_free()
			return

## 現在のイベントシートを削除します。
func remove_sheet_current():
	var sheet = sheets.pop_at(current_sheet_index)
	sheet.queue_free()

## 現在のイベントを削除します。
func remove_event():
	queue_free()

#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------
func _execute_sheet(sheet_node:EventaraSheetNode, is_force:bool):
	if sheet_node.is_running and !is_force:
#	非強制実行かつすでに対象が実行中なら実行しない
		return
	if is_this_frame_running and !event.event_execute_parallel:
#	複数シート同時実行不可かつこのフレームですでに実行中なら実行しない
		return
	if is_this_frame_running and !event.event_execute_parallel:
#	複数シート同時実行不可かつこのフレームですでに実行中なら実行しない
		return
#	var is_runnning_any:bool = sheets.any(func(sheet:EventaraSheetNode): sheet.is_running)
	if sheet_node.is_executable():
		current_sheet_index = sheets.find(sheet_node)
		sheet_node.execute(is_force)
		await sheet_node.event_sheet_finished
