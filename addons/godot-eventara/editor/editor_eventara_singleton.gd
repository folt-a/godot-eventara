#01. tool
@tool
#02. class_name
class_name EventaraEditorSingleton
#03. extends
extends Node
#-----------------------------------------------------------
#04. # docstring
## hoge
#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------

#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------

#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------
const mini_editor_packed = preload("res://addons/godot-eventara/editor/eventara_mini_editor.tscn")
#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------
@onready var interface:EditorInterface = get_tree().get_meta("__editor_interface")

var events:Array[Eventara] = []

var selected_node:Node

var default_size:Vector2 = Vector2(600,600)

var mini_editor:Window = null

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------

func _ready():


	if !ProjectSettings.has_setting("eventara/mini_editor_size"):
		ProjectSettings.set_setting("eventara/mini_editor_size",default_size)

	load_events()
	pass

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------

#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------
func get_icon(icon_name:String,color:Color = Color.WHITE) -> Texture2D:
	var tex:Texture2D = interface.get_base_control().theme.get_icon(icon_name,"EditorIcons")
#	if color != null:
#		var img = tex.get_image()
#		pass
	return tex

func is_selected_eventara_node() -> bool:
	return selected_node != null and selected_node is EventaraNode

## 全イベントを読み込む
func load_events():
	if !ProjectSettings.has_setting("eventara/event_uids"):
#		ProjectSettings.set_setting("eventara/event_uids", [])
		var ev = Eventara.new()
		ev.commands.append("commandA")
		ev.commands.append("commandB")
		ev.commands.append("commandC")
		events.append(ev)
		ResourceSaver.save(ev,"res://eventara.tres")
		var uid = ResourceLoader.get_resource_uid("res://eventara.tres")
		var uidstr = ResourceUID.id_to_text(uid)
		ProjectSettings.set_setting("eventara/event_uids", [uidstr])
		return

	var uids:Array = ProjectSettings.get_setting("eventara/event_uids")
	for uid in uids:
		if ResourceLoader.exists(uid):
#			UID重複チェック
			if !events.has(uid):
				events.append(load(uid))
			else:
				printerr(uid + "is duplicated. ignore this event.")

		else:
			printerr(uid + "is missing. ignore this event.")

func get_mini_editor_default_size() -> Vector2:
	var size = ProjectSettings.get_setting("eventara/mini_editor_size")
	if size.x < 100:
		return Vector2(400,400)
	return size

func set_mini_editor_default_size(size):
	ProjectSettings.set_setting("eventara/mini_editor_size", size)

func create_mini_editor(eventara_node):
	if mini_editor == null:
		mini_editor = mini_editor_packed.instantiate()
		var main_window_position = Vector2(interface.get_editor_main_screen().get_window().position)
		mini_editor.position = main_window_position + Vector2(0, 24)
		interface.get_editor_main_screen().get_window().add_child(mini_editor)
		mini_editor.call_deferred("popup_centered")
	else:
		interface.get_editor_main_screen().get_window().add_child(mini_editor)
		mini_editor.show()
		mini_editor.move_to_foreground()
		mini_editor.reload()

func remove_mini_editor():
#	interface.get_editor_main_screen().get_window().remove_child(mini_editor)
	pass

func create_eventara() -> Eventara:
	return Eventara.new()

#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------

