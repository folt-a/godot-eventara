@tool
extends EditorPlugin

var eventara_path = preload("res://addons/godot-eventara/editor/eventara_main.tscn")
@onready var eventara = eventara_path.instantiate()
var eventrara_editor_s_path = preload("res://addons/godot-eventara/editor/editor_eventara_singleton.tscn")
@onready var eventara_editor_singleton = eventrara_editor_s_path.instantiate()
var eventara_button_path = preload("res://addons/godot-eventara/editor/eventara_button.tscn")
@onready var eventara_button = eventara_button_path.instantiate()

var editable_object:bool = false

func _handles(object):
	pass

func _enter_tree():
	get_tree().set_meta("__editor_interface", get_editor_interface())
	get_tree().set_meta("__undo_redo", get_undo_redo())

func _ready():
	init()
#	add_tool_menu_item("EventEditor",show_mini_editor)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, eventara_button)
	get_editor_interface().get_selection().connect("selection_changed", _on_selection_changed)

	add_autoload_singleton("Evs","res://addons/godot-eventara/eventara_runtime/eventara_singleton.tscn")

func init():
	eventara.visible = false

	get_editor_interface().get_editor_main_screen().add_child(eventara)
	eventara_editor_singleton.interface = get_editor_interface()
	get_tree().set_meta("__eventara_singleton", eventara_editor_singleton)
#	eventara.resource_previewer = get_editor_interface().get_resource_previewer()
#	eventara.editor_interface = get_editor_interface()
#	eventara.undo_redo = get_undo_redo()
#	eventara.init()

func _exit_tree():
	get_editor_interface().get_editor_main_screen().remove_child(eventara)
	eventara.queue_free()

func _on_selection_changed():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1:
		var selected_node = selection[0]
		eventara_editor_singleton.selected_node = selected_node
		if eventara_editor_singleton.selected_node == null:
			eventara_button.hide()
			editable_object = false
		else:
			eventara_button.show()
			editable_object = true
			if selected_node is EventaraNode:
				eventara_button.text = "Event編集"
			else:
				eventara_button.text = "Event作成"
	else:
		editable_object = false
		eventara_button.hide()
	pass

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Event"

func _get_plugin_icon():
	return get_editor_interface().get_base_control().theme.get_icon("Object", "EditorIcons")


func _make_visible(visible):
	eventara.visible = visible
	if visible:
		eventara.show()
