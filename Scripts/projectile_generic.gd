extends Area2D

@export var move_speed: float = 500.0
var target_position: Vector2
var direction: Vector2
var damage: float

var is_enemy_projectile: bool = true

func _ready() -> void:
	direction = (target_position - global_position).normalized()

func _physics_process(delta: float) -> void:
	position += direction * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is PhysicsBody2D or body is Area2D:
		var physics_body := body as CollisionObject2D
		
		if (
			(is_enemy_projectile && physics_body.collision_layer & 1 != 0)
			|| (!is_enemy_projectile && physics_body.collision_layer & 2 != 0)):
				if physics_body.has_method("take_damage"):
					physics_body.take_damage(damage)
				queue_free()

func configure_as_player_projectile() -> void:
	is_enemy_projectile = false
	set_collision_layer_value(3, true)
	set_collision_mask_value(2, true)
	set_animation("player")

func set_animation(anim_name: String) -> void:
	$Sprite2D.play(anim_name)
	$Sprite2D.look_at(target_position)
	
func configure_as_enemy_projectile() -> void:
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
