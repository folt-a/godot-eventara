#01. tool
#02. class_name
class_name EventaraSingleton

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

#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------
var running_events:Dictionary = {}
#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------
var event_nodes:Dictionary = {}

## コモンイベントDic Key=id:StringName, value=EventaraNode
var common_event_nodes:Dictionary = {}
## 現在のシーンイベントDic Key=id:StringName, value=EventaraNode
var scene_event_nodes:Dictionary = {}

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
	pass

#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------

#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------
func add_event_node(event_node:EventaraNode):
	scene_event_nodes[event_node.event_id] = event_node

func remove_event_node(event_node:EventaraNode):
	scene_event_nodes.erase(event_node)

func get_event(id:StringName) -> Eventara:
	return scene_event_nodes[id]

func get_event_or_null(id:StringName, default = null) -> Eventara:
	return scene_event_nodes.get(id, default)

func get_common_event(id:StringName) -> Eventara:
	return common_event_nodes[id]

#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------

