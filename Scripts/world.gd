extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

var mushie

const Mushie = preload("res://Scenes/mushie.tscn")
const Shooter = preload("res://scenes/shooter.tscn")
const Floater = preload("res://scenes/floater.tscn")
const ClumperBig = preload("res://scenes/clumper_big.tscn")
const ClumperMedium = preload("res://scenes/clumper_medium.tscn")
const ClumperSmall = preload("res://scenes/clumper_small.tscn")
const TreeObstacle = preload("res://scenes/tree.tscn")

func _ready():
	setup_game()
	for x in range(-40, 40):
		for y in range(-40, 40):
			var coords = Vector2i(x, y)
			tilemap.set_cell(coords, 0, Vector2i(0,0))

func setup_game():
	for x in range(-40, 40):
		for y in range(-40, 40):
			var coords = Vector2i(x, y)
			tilemap.set_cell(coords, 0, Vector2i(0,0))
	mushie = Mushie.instantiate()
	add_child(mushie)
	mushie.global_position = Vector2(0,0)
	mushie.mushie_dead.connect(freeze_enemies)
	mushie.menu.connect(end_game)

func freeze_enemies():
	$EnemySpawnTimer.paused = true
	for child in get_children():
		if child.is_in_group("enemy") or child.is_in_group("projectile") or child.is_in_group("trees"):
			child.set_physics_process(false)

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
		
		var new_atlas_coords: Vector2i = Vector2i(0, new_linear_index)
		tilemap.set_cell(cell, source_id, new_atlas_coords)

func new_enemy() -> void:
	var new_enemy
	var enemy_choice = randf()
	var is_clumper = false
	if (enemy_choice >= 0.8):
		new_enemy = Shooter.instantiate()
	elif (enemy_choice >= 0.5):
		new_enemy = ClumperBig.instantiate()
		is_clumper = true
	else:
		new_enemy = Floater.instantiate() 
	new_enemy.player = mushie
	add_child(new_enemy)
	
	if is_clumper:
		new_enemy.enemy_dead.connect(clumper_split)
	else:
		new_enemy.enemy_dead.connect(enemy_death_growth)
	
	# Generate a location
	var player_position = mushie.global_position
	var angle = randf_range(0, TAU) # TAU = 2π
	var spawn_radius = 1200
	var x = player_position.x + spawn_radius * cos(angle)
	var y = player_position.y + spawn_radius * sin(angle)
	
	new_enemy.global_position = Vector2(x,y)

func _on_enemy_spawn_timer_timeout() -> void:
	new_enemy()
	pass # Replace with function body.

func end_game():
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
