class_name Enemy extends CharacterBody2D

@export var hit_points: int
@export var move_speed: int
@export var attack_damage: int
@export var growth_on_death: int
@export var has_ranged_attack: bool

func move_towards_player(speed: int) -> void:
	var player = get_tree().get_current_scene().get_node("Mushie")
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Flip sprite depending on direction
		var sprite = $AnimatedSprite2D
		sprite.flip_h = player.global_position.x > global_position.x

func take_damage(dmg:int):
	pass

func die(growth_on_death:int):
	pass

func attack(attack_damage:int):
	pass
