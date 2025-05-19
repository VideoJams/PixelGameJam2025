extends CharacterBody2D

@onready var pellet_scene: PackedScene = preload("res://Scenes/projectile_generic.tscn")
@onready var points_UI = $Control/Points
@onready var audio_player = $AudioStreamPlayer2D

var points = 0
var display_growth = 0
var total_trees = 0
var quota = 30
var next_quota = 40
@export var moveSpeed = 200.0

@export var max_health = 50.0
@export var health = 50.0
@export var damage = 10.0

var sound_shoot = preload("res://Assets/Sounds/player_shoot.ogg")
var sound_hurt = preload("res://Assets/Sounds/player_hurt.ogg")
var sound_quota  = preload("res://Assets/Sounds/quota_reached.ogg")

var can_shoot: bool = true
var can_take_damage: bool = true

signal quota_reached
signal resume
signal mushie_dead
signal menu

func _ready() -> void:
	set_max_health(max_health)
	
	# hi zach :3
	upgrade_projectile_count()
	upgrade_attack_speed()
	upgrade_projectile_count()
	upgrade_attack_speed()

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_handle_animation()
	move_and_slide()
	
	if can_take_damage:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider is PhysicsBody2D or collider is Area2D:
				if (collider.collision_layer & (1 << 1)) != 0:
					take_damage(10)

func _handle_input(delta: float):
	var inputVector = Vector2.ZERO
	inputVector.x = Input.get_axis("left", "right")
	inputVector.y = Input.get_axis("up", "down")
	if inputVector.length() > 0:
		inputVector = inputVector.normalized()
	velocity = inputVector * moveSpeed

	var base_direction = (get_global_mouse_position() - $HandSprite/Marker2D.global_position).normalized()
	if can_shoot && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for i in range(projectile_count):
			var pellet_instance = pellet_scene.instantiate()
			pellet_instance.global_position = $HandSprite/Marker2D.global_position
			
			# Calculate spread for this pellet
			if projectile_count > 1:
				var t = i / float(projectile_count - 1)  # Normalized from 0 to 1
				var angle_offset_degrees = (t - 0.5) * split_shot_angle
				var angle_offset_radians = angle_offset_degrees * PI / 180.0
				var rotated_direction = base_direction.rotated(angle_offset_radians)
				pellet_instance.target_position = global_position + rotated_direction * 1000
			else:
				pellet_instance.target_position = get_global_mouse_position()
			
			pellet_instance.damage = damage
			pellet_instance.move_speed = 800.0
			pellet_instance.configure_as_player_projectile()
			get_tree().current_scene.add_child(pellet_instance)
			audio_player.stream = sound_shoot
			audio_player.pitch_scale = randf_range(0.8, 1.2)
			audio_player.play()
			$AttackTimer.start()
			$HandSprite.play("shoot", 3)
			can_shoot = false

func _handle_animation():
	if can_take_damage:
		if velocity.length() > 0:
			$AnimatedSprite2D.play("walk", 2)
		else:
			$AnimatedSprite2D.play("idle", 1)
			
	var global_mouse = get_global_mouse_position()
	var flip = global_mouse.x < global_position.x
	$AnimatedSprite2D.flip_h = flip
	$HandSprite.look_at(global_mouse)
	$HandSprite.flip_v = flip

func add_growth_quota(growth):
	display_growth += growth
	if display_growth >= quota:
		quota_reached_show_upgrades()
	
	$Control/Quota.text = "Quota: %d/%d" % [display_growth, quota]

func quota_reached_show_upgrades():
	set_physics_process(false)
	emit_signal("quota_reached") #Freeze enemies, decrease enemy spawn timer
	oneoff_sound(sound_quota)
	display_growth = 0
	quota = next_quota
	next_quota += 10
	add_points(5)
	show_upgrade_menu()

func add_points(point_add: int):
	points += point_add
	$Control/Points.text = "Points: %d" % points

func show_upgrade_menu():
	$Control/UpgradeMenu.visible = true
	#TODO: upgrade buttons text and functionality

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
	if can_take_damage:
		health -= damage
		$Control/HealthBar.value = health
		oneoff_sound(sound_hurt)
		
		if health <= 0:
			die()
		else:
			can_take_damage = false
			set_collision_mask_value(2, false)
			$TakeDamageTimer.start()
			$AnimatedSprite2D.play("take_damage", 1)

func die():
	set_physics_process(false)
	emit_signal("mushie_dead")
	$AnimatedSprite2D.play("death")
	#TODO: add empty space to the bottom of the death sprites so mushie is in the center
	$Control/Points.visible = false
	$Control/Quota.visible = false

func _on_timer_timeout() -> void:
	can_shoot = true
	$HandSprite.play("ready")

func _on_take_damage_timer_timeout() -> void:
	set_collision_mask_value(2, true)
	can_take_damage = true

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		$Control/GameOver.visible = true
		$Control/GameOver/GameOverLabel.text = "Game over!
		You grew a total of %d trees" % total_trees

func _on_menu_button_pressed() -> void:
	emit_signal("menu")

func _on_submit_pressed() -> void:
	set_physics_process(true)
	emit_signal("resume")
	$Control/UpgradeMenu.visible = false
	
# Some upgrade functionality ideas because I don't
# know how to expand the UI lmao       -Kaydee

# Upgrading max health also heals to full
func set_max_health(new_value: float) -> void:
	max_health = new_value
	health = new_value
	
	$Control/HealthBar.max_value = new_value
	$Control/HealthBar.value = new_value

# Split shot
var projectile_count = 1
var split_shot_angle = 45
func upgrade_projectile_count() -> void:
	projectile_count += 2
	split_shot_angle = 90 / (projectile_count - 1)
	if split_shot_angle < 9:
		split_shot_angle = 9
	
# +20% attack speed
# 0.5 -> 0.4 -> 0.32 -> 0.256 seconds
func upgrade_attack_speed() -> void:
	$AttackTimer.wait_time *= 0.8
