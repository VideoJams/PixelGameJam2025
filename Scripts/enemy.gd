class_name Enemy extends CharacterBody2D

@onready var player = get_tree().get_current_scene().get_node("Mushie")
@onready var tilemap = get_tree().get_current_scene().get_node("TileMapLayer")

@export var hit_points: float
@export var move_speed: float
@export var attack_damage: float
@export var growth_on_death: int
@export var has_ranged_attack: bool

signal enemy_dead(growth_on_death: int)

enum State { MOVING, ATTACKING, TAKING_DAMAGE, DEAD }

var state: State = State.MOVING
var damage_timer := 0.0
var damage_duration := 0.2  # Seconds of hit freeze

func _physics_process(delta: float) -> void:
	match state:
		State.MOVING:
			$AnimatedSprite2D.play("move")
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
		State.ATTACKING:
			# Stop movement while attacking (attack logic goes elsewhere)
			velocity = Vector2.ZERO
		State.TAKING_DAMAGE:
			velocity = Vector2.ZERO
			damage_timer -= delta
			$AnimatedSprite2D.play("take_damage")
			if damage_timer <= 0.0:
				state = State.MOVING
		State.DEAD:
			$AnimatedSprite2D.play("death")
			velocity = Vector2.ZERO
	$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
	move_and_slide()

#func move_towards_player(speed: float) -> void:
	#var player = get_tree().get_current_scene().get_node("Mushie")
	#if player:
		#var direction = (player.global_position - global_position).normalized()
		#velocity = direction * speed
		#$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		#move_and_slide()

func take_damage(dmg: float) -> void:
	if state != State.TAKING_DAMAGE:
		hit_points -= dmg
		if hit_points <= 0:
			state = State.DEAD
		else:
			state = State.TAKING_DAMAGE
			damage_timer = damage_duration


func create_growth(growth_on_death: int) -> void:
	var enemy_global_pos = global_position
	var local_pos = tilemap.to_local(enemy_global_pos)
	var cell: Vector2i = tilemap.local_to_map(local_pos)
	emit_signal("enemy_death")
	#apply_growth_at_cell(cell, growth_on_death)
	queue_free()


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		create_growth(growth_on_death)
