class_name Floater extends Enemy

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
