class_name Enemy extends CharacterBody2D

@onready var player = get_tree().get_current_scene().get_node("Mushie")
@onready var pellet_scene: PackedScene = preload("res://Scenes/projectile_generic.tscn")

@export var hit_points: float
@export var move_speed: float
@export var attack_damage: float
@export var growth_on_death: int
@export var has_ranged_attack: bool
@export var attack_range: float 
@export var attack_cooldown: float
@export var attack_releases_on_frame: int

signal enemy_dead(pos: Vector2, growth_amount: int)

enum State { MOVING, ATTACKING, TAKING_DAMAGE, DEAD }

var state: State = State.MOVING
var damage_timer := 0.0
var damage_duration := 0.2  # Seconds of hit freeze
var canAttack: bool = true

func _ready() -> void:
	$AttackTimer.wait_time = attack_cooldown

func _physics_process(delta: float) -> void:
	match state:
		State.MOVING:
			$AnimatedSprite2D.play("move")
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			
			if (canAttack):
				if (global_position.distance_to(player.global_position) <= attack_range):
					state = State.ATTACKING
					canAttack = false
		State.ATTACKING:
			# Stop movement while attacking (attack logic goes elsewhere)
			$AnimatedSprite2D.play("attack")
			velocity = Vector2.ZERO
		State.TAKING_DAMAGE:
			velocity = Vector2.ZERO
			damage_timer -= delta
			$AnimatedSprite2D.play("take_damage")
			if damage_timer <= 0.0:
				state = State.MOVING
		State.DEAD:
			$AnimatedSprite2D.play("death")
			$CollisionShape2D.disabled = true
			velocity = Vector2.ZERO
	$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
	move_and_slide()

#func move_towards_player(speed: float) -> void:
	#var player = get_tree().get_current_scene().get_node("Mushie")
	#if player:
		#var direction = (player.global_position - global_position).normalized()
		#velocity = direction * speed
		#$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		#move_and_slidew()

func take_damage(dmg: float) -> void:
	hit_points -= dmg
	if hit_points <= 0:
		state = State.DEAD
	elif state != State.TAKING_DAMAGE:
		# You can hit enemies while they're stunned, but you can't stunlock them
		# without perfectly timing when they break out of stun
		state = State.TAKING_DAMAGE
		damage_timer = damage_duration

func _on_animated_sprite_2d_animation_finished() -> void:
	match ($AnimatedSprite2D.animation):
		"death":
			emit_signal("enemy_dead", global_position, growth_on_death)
			queue_free()
		"attack":
			state = State.MOVING

func _on_attack_timer_timeout() -> void:
	canAttack = true
	
func attack() -> void:
	pass


func _on_animated_sprite_2d_frame_changed() -> void:
	if ($AnimatedSprite2D.animation == "attack" && $AnimatedSprite2D.frame == attack_releases_on_frame):
		attack()
		$AttackTimer.start()
