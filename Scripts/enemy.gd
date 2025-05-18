class_name Enemy extends CharacterBody2D

@export var hit_points: float
@export var move_speed: float
@export var attack_damage: float
@export var growth_on_death: int
@export var has_ranged_attack: bool
@export var attack_range: float 
@export var attack_cooldown: float
@export var attack_releases_on_frame: int

@export var sound_attack_startup: AudioStream
@export var sound_attack_launch: AudioStream
@export var sound_hurt: AudioStream
@export var sound_die: AudioStream

var state: State = State.MOVING
var damage_timer: float = 0.0
var damage_duration: float = 0.2
var can_attack: bool = true
var player
@onready var pellet_scene: PackedScene = preload("res://Scenes/projectile_generic.tscn")
@onready var audio_player = $AudioStreamPlayer2D

signal enemy_dead(pos: Vector2, growth_amount: int)

enum State { MOVING, ATTACKING, TAKING_DAMAGE, DEAD }

func _ready() -> void:
	#initialize enemy specific values
	$AttackTimer.wait_time = attack_cooldown
	$Control/HealthBar.max_value = hit_points

func _physics_process(delta: float) -> void:
	match state:
		State.MOVING:
			$AnimatedSprite2D.play("move")
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
			
			if (can_attack):
				if (global_position.distance_to(player.global_position) <= attack_range):
					play_sound(sound_attack_startup)
					state = State.ATTACKING
					can_attack = false
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
	move_and_slide()

#func move_towards_player(speed: float) -> void:
	#var player = get_tree().get_current_scene().get_node("Mushie")
	#if player:
		#var direction = (player.global_position - global_position).normalized()
		#velocity = direction * speed
		#$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		#move_and_slidew()

func die() -> void:
	state = State.DEAD
	$AnimatedSprite2D.play("death")
	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)
	# $CollisionShape2D.disabled = true
	velocity = Vector2.ZERO
	play_sound(sound_die)

func take_damage(dmg: float) -> void:
	hit_points -= dmg
	$Control/HealthBar.value = hit_points
	$Control/HealthBar.visible = true
	if hit_points <= 0:
		die()
	else:
		play_sound(sound_hurt)
		if state != State.TAKING_DAMAGE:
			# You can hit enemies while they're stunned, but you can't stunlock them
			# without perfectly timing when they break out of stun
			state = State.TAKING_DAMAGE
			damage_timer = damage_duration

func _on_animated_sprite_2d_animation_finished() -> void:
	match ($AnimatedSprite2D.animation):
		"death":
			emit_signal("enemy_dead", global_position, growth_on_death)
			misc_death_properties()
			queue_free()
		"attack":
			state = State.MOVING

func _on_attack_timer_timeout() -> void:
	can_attack = true
	
func attack() -> void:
	pass
	
func misc_death_properties() -> void:
	pass
	
func play_sound(sound: AudioStream):
	audio_player.stream = sound
	audio_player.pitch_scale = randf_range(0.8, 1.2)
	audio_player.play()


func _on_animated_sprite_2d_frame_changed() -> void:
	if ($AnimatedSprite2D.animation == "attack" && $AnimatedSprite2D.frame == attack_releases_on_frame):
		play_sound(sound_attack_launch)
		attack()
		$AttackTimer.start()
