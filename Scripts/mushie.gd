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
@export var damage = 8.0

var sound_shoot = preload("res://Assets/Sounds/player_shoot.ogg")
var sound_hurt = preload("res://Assets/Sounds/player_hurt.ogg")
var sound_quota  = preload("res://Assets/Sounds/quota_reached.ogg")

var can_shoot: bool = true
var can_take_damage: bool = true

signal quota_reached
signal resume
signal mushie_dead
signal menu

const UPGRADE_OPTIONS = [
	{
		"name": "Half HP Restore",
		"description": "Restore half of your hit points.",
		"cost": 50,
		"action": "restore_half_hp"
	},
	{
		"name": "Full HP Restore",
		"description": "Fully restore your hit points.",
		"cost": 30,
		"action": "restore_full_hp"
	},
	{
		"name": "Increase Max HP",
		"description": "Increase maximum HP by 10%.",
		"cost": 15,
		"action": "upgrade_max_hp"
	},
	{
		"name": "Increase Fire Rate",
		"description": "Slightly reduce time between firing.",
		"cost": 15,
		"action": "upgrade_attack_speed"
	},
	{
		"name": "Fire more pellets",
		"description": "Fire a greater number of seeds with each shot.",
		"cost": 45,
		"action": "upgrade_attack_count"
	}
]

func _ready() -> void:
	# hi zach :3
	# XD rofl
	pass

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
	points += 30
	$Control/UpgradeMenu/UpgradeTexture/UpgradePoints.text = str(points)
	
	var upgrade_slots = [ # UI elements references
		{ "cost_label": $Control/UpgradeMenu/Option1/UpgradeCost1,
		  "text_label": $Control/UpgradeMenu/Option1/UpgradeText1,
		  "button": $Control/UpgradeMenu/Option1
		},
		{ "cost_label": $Control/UpgradeMenu/Option2/UpgradeCost2,
		  "text_label": $Control/UpgradeMenu/Option2/UpgradeText2,
		  "button": $Control/UpgradeMenu/Option2
		},
		{ "cost_label": $Control/UpgradeMenu/Option3/UpgradeCost3,
		  "text_label": $Control/UpgradeMenu/Option3/UpgradeText3,
		  "button": $Control/UpgradeMenu/Option3
		}
	]
	var shuffled_upgrades = UPGRADE_OPTIONS.duplicate()
	shuffled_upgrades.shuffle()
	
	for i in range(upgrade_slots.size()): #setup upgrade buttons
		var upgrade = shuffled_upgrades[i]
		var slot = upgrade_slots[i]
		
		slot["cost_label"].text = str(upgrade.cost) #TODO increase this number with each round
		slot["text_label"].text = upgrade.description
		slot["button"].button_pressed = false
		slot["button"].set_meta("upgrade_data", upgrade)
		slot["button"].disabled = points < upgrade.cost

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
	var buttons = [
		$Control/UpgradeMenu/Option1,
		$Control/UpgradeMenu/Option2,
		$Control/UpgradeMenu/Option3
	]
	var total_cost = 0
	var selected_upgrades = []
	#ensure we have enough points for upgrades, else return
	for button in buttons:
		if button.button_pressed:
			var upgrade = button.get_meta("upgrade_data")
			total_cost += upgrade.cost
			selected_upgrades.append(upgrade)
	if total_cost > points:
		#TODO error sound effect?
		return
	
	#apply selected upgrades
	for upgrade in selected_upgrades:
		points -= upgrade.cost
		call(upgrade.action)
	
	#resume game
	set_physics_process(true)
	emit_signal("resume")
	$Control/UpgradeMenu.visible = false

func upgrade_max_hp() -> void:
	max_health += 30
	$Control/HealthBar.max_value = max_health

# Split shot
@export var projectile_count = 1
var split_shot_angle = 45
func upgrade_attack_count() -> void:
	projectile_count += 1
	split_shot_angle = 90 / (projectile_count - 1)
	if split_shot_angle < 9:
		split_shot_angle = 9

func upgrade_attack_speed() -> void:
	$AttackTimer.wait_time *= 0.9 # +10% attack speed

func restore_half_hp() -> void:
	health = max(max_health, health + max_health/2)

func restore_full_hp() -> void:
	health = max_health
