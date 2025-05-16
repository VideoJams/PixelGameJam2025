extends CharacterBody2D

@onready var pellet_scene: PackedScene = preload("res://Scenes/pellet.tscn")

@export var moveSpeed = 200.0
@export var health = 250.0
@export var damage = 10.0

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_handle_animation()
	move_and_slide()

func _handle_input(delta: float):
	var inputVector = Vector2.ZERO
	inputVector.x = Input.get_axis("left", "right")
	inputVector.y = Input.get_axis("up", "down")
	if inputVector.length() > 0:
		inputVector = inputVector.normalized()
	velocity = inputVector * moveSpeed

	if Input.is_action_just_pressed("click"):
		var pellet_instance = pellet_scene.instantiate()
		pellet_instance.global_position = $HandSprite/Marker2D.global_position
		pellet_instance.target_position = get_global_mouse_position()
		pellet_instance.damage = damage
		get_tree().current_scene.add_child(pellet_instance)


func _handle_animation():
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
	$HandSprite.look_at(get_global_mouse_position())
