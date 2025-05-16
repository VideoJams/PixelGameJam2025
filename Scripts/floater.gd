class_name Floater extends Enemy

func _physics_process(delta: float) -> void:
	move_towards_player(move_speed)
