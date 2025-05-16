extends Area2D

@export var move_speed: float = 500.0
var target_position: Vector2
var direction: Vector2
var damage: float

func _ready() -> void:
	direction = (target_position - global_position).normalized()

func _physics_process(delta: float) -> void:
	position += direction * move_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
