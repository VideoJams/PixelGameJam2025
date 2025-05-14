extends CharacterBody2D

@export
var moveSpeed = 300

func _physics_process(delta: float) -> void:
	handle_input(delta)
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
	move_and_slide()
	
func handle_input(delta: float) -> void:
	var inputVector = Vector2.ZERO
	inputVector.x = Input.get_axis("left", "right")
	inputVector.y = Input.get_axis("up", "down")
	
	velocity = inputVector * moveSpeed
	
