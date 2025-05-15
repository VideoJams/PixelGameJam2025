extends CharacterBody2D

@export
var moveSpeed = 200

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_handle_animation()
	move_and_slide()
	
func _handle_input(delta: float) -> void:
	var inputVector = Vector2.ZERO
	inputVector.x = Input.get_axis("left", "right")
	inputVector.y = Input.get_axis("up", "down")
	if inputVector.length() > 0: inputVector = inputVector.normalized()
	velocity = inputVector * moveSpeed

func _handle_animation():
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
	$HandSprite.look_at(get_global_mouse_position())
