extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

var mushie
var rounds = 0

const Mushie = preload("res://Scenes/mushie.tscn")
const Shooter = preload("res://Scenes/shooter.tscn")
const Floater = preload("res://Scenes/floater.tscn")
const ClumperBig = preload("res://Scenes/clumper_big.tscn")
const ClumperMedium = preload("res://Scenes/clumper_medium.tscn")
const ClumperSmall = preload("res://Scenes/clumper_small.tscn")
const MushieHrt = preload("res://Scenes/mushie_hrt.tscn")
const Snake = preload("res://Scenes/snake.tscn")
const Aganyasper = preload("res://Scenes/aganyasper.tscn")

const TreeObstacle = preload("res://Scenes/tree.tscn")

const MAP_MIN = -40
const MAP_MAX = 40
func _ready():
	setup_game()
	for x in range(MAP_MIN, MAP_MAX + 1):
		for y in range(MAP_MIN, MAP_MAX + 1):
			var coords = Vector2i(x, y)
			tilemap.set_cell(coords, 0, Vector2i(0,0))
			
	randomize()
	_init_grid()

func setup_game():
	for x in range(-40, 40):
		for y in range(-40, 40):
			var coords = Vector2i(x, y)
			tilemap.set_cell(coords, 0, Vector2i(0,0))
	mushie = Mushie.instantiate()
	add_child(mushie)
	mushie.global_position = Vector2(0,0)
	mushie.quota_reached.connect(quota_reached)
	mushie.resume.connect(unfreeze_enemies)
	mushie.mushie_dead.connect(freeze_enemies)

func quota_reached():
	rounds+=1
	freeze_enemies()
	$EnemySpawnTimer.wait_time = max(0.5, $EnemySpawnTimer.wait_time - 0.1)

func freeze_enemies():
	$EnemySpawnTimer.paused = true
	for child in get_children():
		if child.is_in_group("enemy") or child.is_in_group("projectile") or child.is_in_group("trees"):
			child.set_physics_process(false)
			if child.has_node("AnimatedSprite2D"): #pause attack animations so they don't fire during freeze
				child.get_node("AnimatedSprite2D").pause()

func unfreeze_enemies():
	$EnemySpawnTimer.paused = false
	for child in get_children():
		if child.is_in_group("enemy") or child.is_in_group("projectile") or child.is_in_group("trees"):
			child.set_physics_process(true)
			if child.has_node("AnimatedSprite2D"):
				child.get_node("AnimatedSprite2D").play()

const EVEN_Q_DIRECTIONS = [
	Vector2i(+1, 0),  # E
	Vector2i(0, -1),  # NE
	Vector2i(-1, -1), # NW
	Vector2i(-1, 0),  # W
	Vector2i(-1, +1), # SW
	Vector2i(0, +1)   # SE
]

const ODD_Q_DIRECTIONS = [
	Vector2i(+1, 0),  # E
	Vector2i(+1, -1), # NE
	Vector2i(0, -1),  # NW
	Vector2i(-1, 0),  # W
	Vector2i(0, +1),  # SW
	Vector2i(+1, +1)  # SE
]

# Get neighbors of a hex tile at axial coordinates (q, r)
func get_hex_neighbors(center: Vector2i) -> Array[Vector2i]:
	var col = center.x
	var row = center.y
	var directions: Array[Vector2i] = []

	if col % 2 == 0:
		directions = [
			Vector2i(+1, 0), Vector2i(0, -1), Vector2i(-1, -1),
			Vector2i(-1, 0), Vector2i(-1, +1), Vector2i(0, +1)
		]
	else:
		directions = [
			Vector2i(+1, 0), Vector2i(+1, -1), Vector2i(0, -1),
			Vector2i(-1, 0), Vector2i(0, +1), Vector2i(+1, +1)
		]
	
	var neighbors: Array[Vector2i] = []
	for dir in directions:
		neighbors.append(center + dir)
	
	return neighbors

func clumper_split(enemy_pos: Vector2, split_index: int) -> void:
	for i in range(2):
		var new_enemy
		if split_index == 0:
			new_enemy = ClumperMedium.instantiate()
			new_enemy.enemy_dead.connect(clumper_split)
		else:
			new_enemy = ClumperSmall.instantiate()
			new_enemy.enemy_dead.connect(enemy_death_growth)
			
		new_enemy.player = mushie
		add_child(new_enemy)
		
		var new_x = enemy_pos.x -150 + (randf() * 300)
		var new_y = enemy_pos.y -150 + (randf() * 300)
		
		new_enemy.global_position = Vector2(new_x, new_y)

func enemy_death_growth(enemy_pos: Vector2, growth_epicenter: int) -> void:
	mushie.enemies_killed += 1
	var enemy_pos_to_tilemap = tilemap.to_local(enemy_pos)
	var cell: Vector2i = tilemap.local_to_map(enemy_pos_to_tilemap)
	apply_growth_on_cell(cell, growth_epicenter)
	
	var neighbors = get_hex_neighbors(cell)
	var neighborGrowth = growth_epicenter - 1
	for n in neighbors:
		apply_growth_on_cell(n, neighborGrowth)

func apply_growth_on_cell(cell: Vector2i, growth_increase: int) -> void:
	#These will need to csdashange whenever the TileSet is updated
	var layer_index: int = 0
	
	var source_id: int = tilemap.get_cell_source_id(cell)
	var atlas_coords: Vector2i = tilemap.get_cell_atlas_coords(cell)
	
	var current_linear_index: int = atlas_coords.y
	if current_linear_index < 5:
		var new_linear_index: int = current_linear_index + growth_increase
		mushie.add_growth_quota(growth_increase)
		
		# At 5 (cap at 5), spawn tree
		if new_linear_index >= 5:
			new_linear_index = 5
			var new_tree = TreeObstacle.instantiate()
			add_child(new_tree)
			
			var converted_position = tilemap.to_global(tilemap.map_to_local(cell))
			converted_position.y -= 100
			new_tree.global_position = converted_position
			mushie.add_points(1)
			mushie.total_trees += 1
		
		var new_atlas_coords: Vector2i = Vector2i(atlas_coords.x, new_linear_index)
		tilemap.set_cell(cell, source_id, new_atlas_coords)

func new_enemy() -> void:
	var new_enemy
	var enemy_choice = randf()
	var is_clumper = false
	if (enemy_choice >= 0.85):
		new_enemy = Shooter.instantiate()
	elif (enemy_choice >= 0.7):
		new_enemy = ClumperBig.instantiate()
		is_clumper = true
	elif (enemy_choice >= 0.55):
		new_enemy = Aganyasper.instantiate()
	elif (enemy_choice >= 0.4):
		new_enemy = MushieHrt.instantiate()
	elif (enemy_choice >= 0.25):
		new_enemy = Snake.instantiate()
	else:
		new_enemy = Floater.instantiate() 
	new_enemy.player = mushie
	
	if is_clumper:
		new_enemy.enemy_dead.connect(clumper_split)
		if $EnemySpawnTimer.paused: #Don't let clumpers act if game is paused
			new_enemy.set_physics_process(false)
	else:
		new_enemy.enemy_dead.connect(enemy_death_growth)
	
	# Scale difficulty
	new_enemy.scale_difficulty(rounds)
	
	# Generate a location
	var player_position = mushie.global_position
	var angle = randf_range(0, TAU) # TAU = 2π
	var spawn_radius = 1200
	var x = player_position.x + spawn_radius * cos(angle)
	var y = player_position.y + spawn_radius * sin(angle)
	new_enemy.global_position = Vector2(x,y)
	
	add_child(new_enemy)

func _on_enemy_spawn_timer_timeout() -> void:
	new_enemy()
	pass # Replace with function body.

func end_game():
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")


# Tile Atlas X values for different states
var current_state = []
var next_state = []

func _init_grid():
	var size = MAP_MAX - MAP_MIN
	current_state.resize(size)
	next_state.resize(size)
	for x in range(size):
		current_state[x] = []
		next_state[x] = []
		for y in range(size):
			var state = randi() % 7  # 7 different states
			current_state[x].append(state)
			next_state[x].append(0)
			
	for i in range(50):
		_step_automata()
		
	for x in range(MAP_MIN, MAP_MAX + 1):
		for y in range(MAP_MIN, MAP_MAX + 1):
			var cell = Vector2(x, y)
			var source_id: int = tilemap.get_cell_source_id(cell)
			
			var new_atlas_coords: Vector2i = Vector2i(current_state[x][y], 0)
			tilemap.set_cell(cell, source_id, new_atlas_coords)

func _step_automata():
	var size = MAP_MAX - MAP_MIN
	for x in range(size):
		for y in range(size):
			var count = _count_neighbors(x, y)
			# Example rule: Increase state if more than 3 neighbors
			var state = current_state[x][y]
			if count > 3:
				state = (state + 1) % 4
			next_state[x][y] = state
	
	# Swap current and next
	var temp = current_state
	current_state = next_state
	next_state = temp

func _count_neighbors(x, y):
	var count = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= MAP_MIN && ny >= MAP_MIN && nx <= MAP_MAX && ny <= MAP_MAX:
				if current_state[nx][ny] != 0:
					count += 1  # count non-zero tiles
	return count
