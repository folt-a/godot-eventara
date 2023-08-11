#01. tool
@tool
#02. class_name

#03. extends
extends Window
#-----------------------------------------------------------
#04. # docstring
## イベントミニエディタ

#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------

#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------
enum SheetExecuteTypeOption{
	ScriptRun = 0,
	AutoStart = 1,
	PROCESS = 2,
}
const SheetExecuteTypeOptionString = {
	SheetExecuteTypeOption.ScriptRun : "外部実行のみ",
	SheetExecuteTypeOption.AutoStart : "自動実行",
	SheetExecuteTypeOption.PROCESS : "毎フレーム実行",
}

enum EventExecuteParallelOption{
	SINGLE = 0,
	PARALLEL = 1,
}
const EventExecuteParallelOptionString = {
	EventExecuteParallelOption.SINGLE : "1シートずつ実行(先頭のシートが優先)",
	EventExecuteParallelOption.PARALLEL : "複数シート同時並列実行",
}

#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------
var eventara:Eventara
var eventara_uid:int = -1
var _selected_sheet_index:int = 0
var working_sheets:Array[EventaraSheet] = []
var sheet_uids:Array[int] = []
var current_script:GDScript

var template_code:String
var template_code_replaced:String

var _is_dirty:bool = false

var save_path:String = "res://eventara/"

# Godot ScriptEditor
var script_editor:ScriptEditor
var script_editor_base:ScriptEditorBase
var script_editor_parent:Node

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------
@onready var ev_edit_s:EventaraEditorSingleton = get_tree().get_meta("__eventara_singleton") if get_tree().has_meta("__eventara_singleton") else null
@onready var interface:EditorInterface
@onready var selected_node:EventaraNode
@onready var parent_node:Node

@onready var script_edit_margin_container:MarginContainer = %ScriptEditMarginContainer
@onready var commands_code_edit:CodeEdit = %CommandsCodeEdit
@onready var msg_rich_text_label:RichTextLabel = %MsgRichTextLabel

@onready var eventara_mini_editor_h_split:HSplitContainer = %EventaraMiniEditorHSplit

@onready var sidebar_v_box_container:VBoxContainer = %SidebarVBoxContainer

# Side Bar
@onready var sidebar_row_1 = %SidebarRow1
@onready var sidebar_row_2 = %SidebarRow2
@onready var sidebar_row_3 = %SidebarRow3
@onready var event_sheet_label_row = %EventSheetLabelRow
@onready var sheet_list:ItemList = %SheetList
@onready var sidebar_bottom_row_1 = %SidebarBottomRow1

# Side Bar Buttons
@onready var save_button:Button = %SaveButton
@onready var visible_button:Button = %VisibleButton
@onready var add_button:Button = %AddButton
@onready var duplicate_button:Button = %DuplicateButton
@onready var rename_button:Button = %RenameButton
@onready var remove_button:Button = %RemoveButton

@onready var save_button_2:Button = %SaveButton2

@onready var setting_visible_button = %SettingVisibleButton
@onready var sidebar_hidden_h_box_container:HBoxContainer = %SidebarHiddenHBoxContainer

@onready var confirmation_dialog:ConfirmationDialog = $ConfirmationDialog

@onready var event_id_line_edit:LineEdit = %EventIdLineEdit

# シート設定
@onready var sheet_execute_type_option_button:OptionButton = %SheetExecuteTypeOptionButton
@onready var sheet_execute_type_default_update_button:Button = %SheetExecuteTypeDefaultUpdateButton

# イベント設定
@onready var event_parallel_option_button:OptionButton = %EventParallelOptionButton
@onready var event_parallel_default_update_button:Button = %EventParallelDefaultUpdateButton

@onready var save_resources_path_line_edit:LineEdit = %SaveResourcesPathLineEdit


#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------

func _ready():
	if ev_edit_s == null:return
	interface = ev_edit_s.interface
	commands_code_edit.visible = false #TODO
	commands_code_edit.text_changed.connect(_on_commands_code_edit_text_changed)

	about_to_popup.connect(_on_about_to_popup)
	close_requested.connect(_on_close_requested)
	size_changed.connect(_on_size_changed)
	size = ev_edit_s.get_mini_editor_default_size()

	confirmation_dialog.confirmed.connect(_on_confirm_ok)
	confirmation_dialog.canceled.connect(_on_confirm_cancel)
	confirmation_dialog.custom_action.connect(_on_confirm_delete)
	confirmation_dialog.add_button("破棄する",true,"delete")

	save_button.icon = ev_edit_s.get_icon("Save")
#	save_button.size = save_button.size * Vector2(2,1)
	visible_button.icon = ev_edit_s.get_icon("GuiVisibilityVisible")
	add_button.icon = ev_edit_s.get_icon("Add")
	duplicate_button.icon = ev_edit_s.get_icon("Duplicate")
	rename_button.icon = ev_edit_s.get_icon("Edit")
	remove_button.icon = ev_edit_s.get_icon("Remove")

	save_button_2.icon = ev_edit_s.get_icon("Save")
	init()

func init():
	init_sheet_setting()
	init_event_setting()

#	デフォルト設定の更新ボタン
	sheet_execute_type_default_update_button.icon = ev_edit_s.get_icon("ArrowRight")
	sheet_execute_type_default_update_button.tooltip_text = "デフォルト値を上書き"
	sheet_execute_type_default_update_button.connect("pressed",\
	func(): update_default("sheet_execute_type",sheet_execute_type_option_button.selected))

	event_parallel_default_update_button.icon = ev_edit_s.get_icon("ArrowRight")
	event_parallel_default_update_button.tooltip_text = "デフォルト値を上書き"
	event_parallel_default_update_button.connect("pressed",\
	func(): update_default("event_parallel",event_parallel_option_button.selected))

#	設定
	if ProjectSettings.has_setting("eventara/save_path"):
		save_path = ProjectSettings.get_setting("eventara/save_path") as String

	var file = FileAccess.open("res://addons/godot-eventara/editor/template/templete_sheet_edit.txt",FileAccess.READ)
	template_code = file.get_as_text()
	file.close()

	#	スクリプトエディタ借りる
	script_editor = interface.get_script_editor()
	script_editor_base = interface.get_script_editor().get_current_editor()
	script_editor.reset_size()
	edit_script()
	script_editor_parent = script_editor_base.get_parent()



func edit_script():
#	interface.edit_script(current_script,0,0,true)
	if script_editor_base == null:
		await get_tree().create_timer(0.5).timeout
		interface.edit_script(script_editor.get_current_script(),0,0,true)
#		edit_script()


#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------
func _on_about_to_popup():
	reload()

func reload():
	sheet_list.clear()
	working_sheets.clear()
	sheet_uids.clear()
	msg_rich_text_label.text = ""
	selected_node = ev_edit_s.selected_node
	parent_node = selected_node.get_parent()
	var classname:String = get_gori_oshi_class_name()
#	print("classname",classname)
	template_code_replaced = template_code.replace("%CLASSNAME%", classname)
	load_event()

func _on_close_requested():
	if _is_dirty:
		confirmation_dialog.popup_centered() #保存してない警告
	else:
		_on_confirm_delete()

func _on_confirm_ok():
	_on_save_button_pressed()
	get_parent().remove_child(self)
	working_sheets = []
	sheet_uids = []
	current_script = null
	#	スクリプトエディタをお返しする
	script_edit_margin_container.remove_child(script_editor_base)
	script_editor_parent.add_child(script_editor_base)
	hide()
	ev_edit_s.remove_mini_editor()

func _on_confirm_delete():
	get_parent().remove_child(self)
	working_sheets = []
	sheet_uids = []
	current_script = null
	#	スクリプトエディタをお返しする
	script_edit_margin_container.remove_child(script_editor_base)
	script_editor_parent.add_child(script_editor_base)
	hide()
	ev_edit_s.remove_mini_editor()

func _on_confirm_cancel():
	pass

func _on_size_changed():
	if visible and size > Vector2i(10,10):
		ev_edit_s.set_mini_editor_default_size(size)

#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------


#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------

## 保存
func _on_save_button_pressed():
	var res = save_sheet()
	if !res:return
#	saved_eventara.id = eventara.id
#	saved_eventara.event_execute_parallel = eventara.event_execute_parallel
#	var sheets:Array[EventaraSheet] = []
#	var index = 0
#	for sheet_script in working_sheets:
#		var sheet = EventaraSheet.new()
#		sheet.sheet_name = "シート" + str(index)
#		sheet.sheet_script = sheet_script
#		sheets.append(sheet)
#		index += 1
#	saved_eventara.sheets = sheets
	if !DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_recursive_absolute(save_path)

	var ev_path:String = save_path.path_join(eventara.id) + ".tres"

	var saved_eventara_uid:int = ResourceLoader.get_resource_uid(eventara.resource_path)
	if eventara_uid == -1 and saved_eventara_uid != -1:
#			新規作成だが別ファイルがすでにある
		msg_rich_text_label.text = "[color=#ff7085]%s は別シートファイルがすでにあります[/color]" % ev_path
		return
	elif saved_eventara_uid == -1:
#			保存先にないのでOK
		pass
	elif eventara_uid != saved_eventara_uid:
#			別ファイルがすでにある
		msg_rich_text_label.text = "[color=#ff7085]%s は別シートファイルがすでにあります[/color]" % ev_path
		return

	var sheet_index:int = 0
	for uid in sheet_uids:
		var script_path:String = save_path.path_join(eventara.id + "_" + working_sheets[sheet_index].sheet_name) + ".tres"
		var saved_uid:int = ResourceLoader.get_resource_uid(script_path)
		print(uid)
		print(script_path)
		print(saved_uid)
		if uid == -1 and saved_uid != -1:
#			新規作成だが別ファイルがすでにある
			msg_rich_text_label.text = "[color=#ff7085]%s は別シートファイルがすでにあります[/color]" % script_path
			return
		elif saved_uid == -1:
#			保存先にないのでOK
			pass
		elif uid != saved_uid:
#			別ファイルがすでにある
			msg_rich_text_label.text = "[color=#ff7085]%s は別シートファイルがすでにあります[/color]" % script_path
			return
		sheet_index += 1

	sheet_uids = []
	for sheet_script in working_sheets:
		var script_path:String = save_path.path_join(eventara.id + "_" + sheet_script.sheet_name) + ".gd"
		sheet_script.sheet_script.resource_path = script_path
		ResourceSaver.save(sheet_script.sheet_script, script_path, ResourceSaver.FLAG_CHANGE_PATH)

		var sheet_path:String = save_path.path_join(eventara.id + "_" + sheet_script.sheet_name) + ".tres"
		sheet_script.resource_path = sheet_path
		ResourceSaver.save(sheet_script, sheet_path, ResourceSaver.FLAG_CHANGE_PATH)
		sheet_uids.append(ResourceLoader.get_resource_uid(sheet_path))
	eventara.sheets = working_sheets
	ResourceSaver.save(eventara, ev_path, ResourceSaver.FLAG_CHANGE_PATH)
	eventara_uid = ResourceLoader.get_resource_uid(ev_path)
#	ev_edit_s.interface.save_scene()

## サイドバー表示切替
func _on_visible_button_pressed():
	var v = visible_button.button_pressed
	save_button.visible = !v
	sidebar_row_2.visible = !v
	sidebar_row_3.visible = !v
	sheet_list.visible = !v
	event_sheet_label_row.visible = !v
	sidebar_bottom_row_1.visible = !v
	sidebar_v_box_container.size.x = 0

	sidebar_hidden_h_box_container.visible = v

	visible_button.visible = !v
	setting_visible_button.visible = v

	if v:
		visible_button.icon = ev_edit_s.get_icon("GuiVisibilityVisible")
		eventara_mini_editor_h_split.collapsed = true
		eventara_mini_editor_h_split.dragger_visibility = HSplitContainer.DRAGGER_HIDDEN_COLLAPSED
	else:
		visible_button.icon = ev_edit_s.get_icon("GuiVisibilityVisible")
		eventara_mini_editor_h_split.collapsed = false
		eventara_mini_editor_h_split.dragger_visibility = HSplitContainer.DRAGGER_VISIBLE

## サイドバー表示切替（サイドバー非表示時のボタン）
func _on_setting_visible_button_pressed():
	visible_button.button_pressed = false
	_on_visible_button_pressed()

## シート追加
func _on_add_button_pressed():
	var item_name = "sheet_"+ str(working_sheets.size())
	sheet_list.add_item(item_name)
	var sheet = EventaraSheet.new()
	sheet.sheet_name = item_name
	if ProjectSettings.has_setting("eventara/defaults/sheet_execute_type"):
		sheet.sheet_execute_type = ProjectSettings.get_setting("eventara/defaults/sheet_execute_type")
	var new_script = GDScript.new()
	new_script.source_code = template_code_replaced
	sheet.sheet_script = new_script
	working_sheets.append(sheet)
	sheet_uids.append(-1)

## シート選択
func _on_sheet_list_item_selected(index):
	if index == _selected_sheet_index: return
	var res = save_sheet()
	if !res: return
	load_sheet(index)
	_selected_sheet_index = index
	load_editor()

## イベントID変更
func _on_event_id_line_edit_text_changed(new_text):
	eventara.id = new_text

func _on_script_editor_button_pressed():
	interface.edit_script(current_script)


func _on_help_button_pressed():
	pass # Replace with function body.


## コード変更
func _on_commands_code_edit_text_changed():
	_is_dirty = true

# シート設定

## シート　実行タイプ
func _on_sheet_execute_type_option_button_item_selected(index):
	working_sheets[_selected_sheet_index].sheet_execute_type = index

# イベント設定

## イベント　並列実行可否
func _on_event_parallel_option_button_item_selected(index):
	eventara.event_execute_parallel = index

# 共通設定

## 保存パス設定変更
func _on_save_resources_path_line_edit_text_changed(new_text:String):
	if !new_text.is_valid_filename():
		msg_rich_text_label.text = "[color=#ff7085]%s は正しくないパスです[/color]" % new_text
		return
	ProjectSettings.set_setting("eventara/save_path", msg_rich_text_label.text)



#
# ---------------------------------------------------------
#

func get_gori_oshi_class_name() -> String:
	var script:Script = parent_node.get_script()
	if script == null or !script.has_source_code():
		return parent_node.get_class()
	var source_code:String = script.source_code

	var class_name_pattern: String = "^class_name\\s+(\\w+)$"
	var regex = RegEx.new()
	regex.compile(class_name_pattern)

	var lines = source_code.split("\n")
	for line in lines:
		var result = regex.search(line)
		if result:
			return result.get_string(1)
	return parent_node.get_class()

func _load_line(line:String) -> String:
#	コメントチェック
	var regex_comment = RegEx.new()
	regex_comment.compile("\\s*#.*")
	var result_comment = regex_comment.search(line)
	if result_comment:
		return ""

#	@icon("res://icon.svg")
#	iconsチェック
	var regex_icon = RegEx.new()
	regex_icon.compile("\\s*@icon\\(.*")
	var result_icon = regex_icon.search(line)
	if result_icon:
		var icon_pos := line.find("@icon(")
		var icon_path = line.substr(icon_pos + 7).trim_suffix(" ").trim_prefix(" ").trim_suffix(")").trim_suffix("\"")
		return icon_path

	return ""

func load_event():
	if selected_node == null or selected_node.event == null:
		print("new eventara")
		var new_eventara:Eventara = Eventara.new()
#		TODO NEW NAME EVENTARA
		new_eventara.id = "Ev001"
		new_eventara.event_execute_parallel = event_parallel_option_button.selected
		if ProjectSettings.has_setting("eventara/defaults/event_parallel"):
			new_eventara.event_execute_parallel = ProjectSettings.get_setting("eventara/defaults/event_parallel")
		selected_node.event = new_eventara
		eventara_uid = -1
	else:
		var uid:int = ResourceLoader.get_resource_uid(selected_node.event.resource_path)
		eventara_uid = uid
	eventara = selected_node.event
	event_parallel_option_button.select(eventara.event_execute_parallel)
	eventara = selected_node.event
	event_id_line_edit.text = eventara.id

	_selected_sheet_index = 0
	if eventara.sheets.size() != 0:
		load_sheets()
	else:
		_on_add_button_pressed()
	load_sheet(0)
	await get_tree().process_frame
	if script_editor.get_current_script() != current_script:
		interface.edit_script(current_script,0,0,true)
		#	スクリプトエディタ借りる
		script_editor = interface.get_script_editor()
		script_editor_base = interface.get_script_editor().get_current_editor()
		script_editor.reset_size()
		edit_script()
		script_editor_parent = script_editor_base.get_parent()
	await get_tree().process_frame
	script_editor_parent.remove_child(script_editor_base)
	script_edit_margin_container.add_child(script_editor_base)

## 全シート読み込み
func load_sheets():
	sheet_list.clear()
	working_sheets.clear()
	sheet_uids.clear()
#	シート名の読み込み
	for sheet in eventara.sheets:
		sheet_list.add_item(sheet.sheet_name)
		working_sheets.append(sheet)
		var uid:int = ResourceLoader.get_resource_uid(sheet.resource_path)
#		print(sheet.sheet_script.resource_path)
#		print(uid)
		sheet_uids.append(uid)
	if working_sheets.is_empty():
		_on_add_button_pressed()
	load_sheet()

## シート読み込み
func load_sheet(index:int = 0):
	if working_sheets.size() < index:
		printerr("load sheet failed. index="+ str(index) + ", but size=" + str(eventara.sheets.size()))
	current_script = working_sheets[index].sheet_script
	commands_code_edit.text = current_script.source_code

	sheet_execute_type_option_button.select(working_sheets[index].sheet_execute_type)

func load_editor():
	script_edit_margin_container.remove_child(script_editor_base)
	script_editor_parent.add_child(script_editor_base)
	script_editor_parent.move_child(script_editor_base,0)
	interface.edit_script(current_script,-1,0,true)
	await get_tree().process_frame
	script_editor_base = null
	await get_tree().process_frame
	script_editor_base = interface.get_script_editor().get_current_editor()
	script_editor_parent = script_editor_base.get_parent()
	await get_tree().process_frame
	script_editor_parent.remove_child(script_editor_base)
	script_edit_margin_container.add_child(script_editor_base)
	await get_tree().process_frame
	interface.get_script_editor().get_current_editor().grab_click_focus()
	interface.get_script_editor().get_current_editor().release_focus()
	script_editor_base.grab_click_focus()


## シート保存
func save_sheet():
	var value = commands_code_edit.text
	if value == null or value == "": return

	current_script.source_code = value

	var error = current_script.reload()
	if error != OK:
		printerr(error_string(error))
		msg_rich_text_label.text = "[color=#ff7085]%s[/color]" % error_string(error)
		sheet_list.select(_selected_sheet_index, true)
		return false

	msg_rich_text_label.text = ""
	_is_dirty = false
	return true

## シート初期設定
func init_sheet_setting():
#	execute_type_option_button.add_icon_item()
	if sheet_execute_type_option_button.item_count != 0:
		sheet_execute_type_option_button.clear()
	sheet_execute_type_option_button.add_item(SheetExecuteTypeOptionString[SheetExecuteTypeOption.ScriptRun])
	sheet_execute_type_option_button.add_item(SheetExecuteTypeOptionString[SheetExecuteTypeOption.AutoStart])
	sheet_execute_type_option_button.add_item(SheetExecuteTypeOptionString[SheetExecuteTypeOption.PROCESS])

## イベント初期設定
func init_event_setting():
#	execute_type_option_button.add_icon_item()
	if event_parallel_option_button.item_count != 0:
		event_parallel_option_button.clear()
	event_parallel_option_button.add_item(EventExecuteParallelOptionString[EventExecuteParallelOption.SINGLE])
	event_parallel_option_button.add_item(EventExecuteParallelOptionString[EventExecuteParallelOption.PARALLEL])

func update_default(setting_name:String,value):
	ProjectSettings.set_setting("eventara/defaults/" + setting_name, value)



