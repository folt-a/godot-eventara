#01. tool
@tool
#02. class_name

#03. extends
extends Button
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

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------
@onready var eventara_singleton = get_tree().get_meta("__eventara_singleton")
#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------

#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------
func _ready() -> void:
	icon = eventara_singleton.get_icon("Object")
	pressed.connect(_on_pressed)

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------
func _on_pressed():
	var eventara_node:EventaraNode = null
	if !eventara_singleton.is_selected_eventara_node():
		eventara_node = EventaraNode.new()
		eventara_node.name = "Eventara"
		eventara_singleton.selected_node.add_child(eventara_node)
#		eventara_node.event = eventara_singleton.create_eventara()
		eventara_node.owner = eventara_singleton.selected_node.get_tree().edited_scene_root
		eventara_singleton.selected_node = eventara_node
	eventara_singleton.create_mini_editor(eventara_node)



#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------

#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------
