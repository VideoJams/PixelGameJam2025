extends CharacterBody2D

@onready var pellet_scene: PackedScene = preload("res://Scenes/projectile_generic.tscn")
@onready var points_UI = $Control/Points
@onready var audio_player = $AudioStreamPlayer2D

var points = 0
var display_growth = 0
var total_growth = 0
var quota = 30
var next_quota = 40
@export var moveSpeed = 200.0
@export var health = 50.0
@export var damage = 10.0

var sound_shoot = preload("res://Assets/Sounds/player_shoot.ogg")
var sound_hurt = preload("res://Assets/Sounds/player_hurt.ogg")
var sound_quota  = preload("res://Assets/Sounds/quota_reached.ogg")

var can_shoot = true

signal mushie_dead

func _ready() -> void:
	$Control/HealthBar.max_value = health
	$Control/HealthBar.value = health

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

	if can_shoot && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var pellet_instance = pellet_scene.instantiate()
		pellet_instance.global_position = $HandSprite/Marker2D.global_position
		pellet_instance.target_position = get_global_mouse_position()
		pellet_instance.damage = damage
		pellet_instance.move_speed = 800.0
		pellet_instance.configure_as_player_projectile()
		get_tree().current_scene.add_child(pellet_instance)
		audio_player.stream = sound_shoot
		audio_player.pitch_scale = randf_range(0.8, 1.2)
		audio_player.play()
		$AttackTimer.start()
		can_shoot = false


func _handle_animation():
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk", 2)
	else:
		$AnimatedSprite2D.play("idle", 1)
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
	$HandSprite.look_at(get_global_mouse_position())

func add_growth_quota(growth):
	display_growth += growth
	total_growth += growth
	if display_growth >= quota:
		oneoff_sound(sound_quota)
		display_growth = 0
		quota = next_quota
		next_quota += 10
		add_points(5)
		
		
	$Control/Quota.text = "Quota: %d/%d" % [display_growth, quota]


func add_points(point_add: int):
	points += point_add
	$Control/Points.text = "Points: %d" % points

func oneoff_sound(sound: AudioStream):
	# Temporary sound object
	var temp_player = AudioStreamPlayer2D.new()
	temp_player.stream = sound
	temp_player.pitch_scale = randf_range(0.9, 1.1)
	temp_player.global_position = global_position  # for spatial sound
	get_tree().current_scene.add_child(temp_player)
	temp_player.play()
	temp_player.connect("finished", Callable(temp_player, "queue_free"))

func take_damage(damage: float):
	health -= damage
	$Control/HealthBar.value = health
	oneoff_sound(sound_hurt)
	
	if health <= 0:
		die()

func die():
	emit_signal("mushie_dead")


func _on_timer_timeout() -> void:
	can_shoot = true
