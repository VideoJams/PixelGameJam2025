extends Enemy

func attack() -> void:
	# Number of pellets
	var num_pellets = 5
	# Spread angle in degrees (total spread)
	var spread_angle = 30

	# Calculate direction to player
	var base_direction = (player.global_position - global_position).normalized()

	for i in range(num_pellets):
		var pellet_instance = pellet_scene.instantiate()
		pellet_instance.global_position = global_position

		# Calculate spread for this pellet
		var t = i / float(num_pellets - 1)  # Normalized from 0 to 1
		var angle_offset_degrees = (t - 0.5) * 20
		var angle_offset_radians = angle_offset_degrees * PI / 180.0
		var rotated_direction = base_direction.rotated(angle_offset_radians)
		
		# Set the target position far in the direction of the rotated vector
		pellet_instance.target_position = global_position + rotated_direction * 1000
		pellet_instance.set_animation("inky")

		pellet_instance.damage = 10
		pellet_instance.move_speed = 200
		pellet_instance.configure_as_enemy_projectile()
		get_tree().current_scene.add_child(pellet_instance)
