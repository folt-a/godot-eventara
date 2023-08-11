extends TileMap

@onready var eventara:EventaraNode = $Player/Eventara

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
var index:int = 0
var is_lock:bool
func _input(event):
	if is_lock: return
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			is_lock = true
			var ret = await eventara.execute(index)
			print(ret)
			is_lock = false
			if index == 0:
				index = 1
			else:
				index = 0
