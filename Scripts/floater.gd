class_name Floater extends Enemy

func scale_difficulty(rounds: int):
	attack_damage += rounds
	hit_points += rounds*2
	move_speed += rounds*3
	attack_cooldown = max(0.5, attack_cooldown-rounds*0.1)
	$Control/HealthBar.max_value = hit_points
	$Control/HealthBar.value = hit_points

func attack():
	var pellet_instance = pellet_scene.instantiate()
	pellet_instance.global_position = global_position
	pellet_instance.target_position = player.global_position
	pellet_instance.set_animation("floater")
	pellet_instance.damage = 10
	pellet_instance.move_speed = 200
	pellet_instance.configure_as_enemy_projectile()
	get_tree().current_scene.add_child(pellet_instance)
	play_sound(sound_attack_launch)
