extends Enemy

func attack():
	var pellet_instance = pellet_scene.instantiate()
	pellet_instance.global_position = global_position
	pellet_instance.target_position = player.global_position
	pellet_instance.set_animation("inky")
	pellet_instance.damage = 10
	pellet_instance.move_speed = 200
	pellet_instance.configure_as_enemy_projectile()
	get_tree().current_scene.add_child(pellet_instance)

	# Shoots a tricky 2nd projectile at a random angle to try to catch movement
	var pellet_instance2 = pellet_scene.instantiate()
	pellet_instance2.global_position = global_position
	var base_direction = (player.global_position - global_position).normalized()
	var rotated_direction = base_direction.rotated(-90 + (randf() * 180))
	pellet_instance2.target_position = global_position + rotated_direction * 1000
	
	pellet_instance2.set_animation("inky")
	pellet_instance2.damage = 10
	pellet_instance2.move_speed = 200
	pellet_instance2.configure_as_enemy_projectile()
	get_tree().current_scene.add_child(pellet_instance2)
