extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = 0

func _process(delta):
	velocity = Input.get_vector("ui_left", "ui_right","ui_up","ui_down")* SPEED

func _physics_process(delta):
	move_and_slide()
