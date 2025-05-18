extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

var mushie

const Shooter = preload("res://scenes/shooter.tscn")
const Floater = preload("res://scenes/floater.tscn")

const TreeObstacle = preload("res://scenes/tree.tscn")

func _ready():
	for x in range(-40, 40):
		for y in range(-40, 40):
			var coords = Vector2i(x, y)
			tilemap.set_cell(coords, 0, Vector2i(0,0))
			
	mushie = get_node("Mushie")
	
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
	
func enemy_death_growth(enemy_pos: Vector2, growth_epicenter: int) -> void:
	var enemy_pos_to_tilemap = tilemap.to_local(enemy_pos)
	var cell: Vector2i = tilemap.local_to_map(enemy_pos_to_tilemap)
	apply_growth_on_cell(cell, growth_epicenter)

	var neighbors = get_hex_neighbors(cell)
	var neighborGrowth = growth_epicenter - 1
	for n in neighbors:
		apply_growth_on_cell(n, neighborGrowth)
	
func apply_growth_on_cell(cell: Vector2i, growth_increase: int) -> void:
	#These will need to change whenever the TileSet is updated
	var layer_index: int = 0
	
	var source_id: int = tilemap.get_cell_source_id(cell)
	var atlas_coords: Vector2i = tilemap.get_cell_atlas_coords(cell)
	
	var current_linear_index: int = atlas_coords.x
	
	if current_linear_index < 4:
		var new_linear_index: int = current_linear_index + growth_increase
		
		# At 4 (cap at 4), spawn tree
		if new_linear_index >= 4:
			new_linear_index = 4
			var new_tree = TreeObstacle.instantiate()
			add_child(new_tree)
			new_tree.global_position = tilemap.to_global(tilemap.map_to_local(cell))
			new_tree.z_index = int(global_position.y)
			
		var new_atlas_coords: Vector2i = Vector2i(new_linear_index, 0)
		tilemap.set_cell(cell, source_id, new_atlas_coords)
	
func new_enemy() -> void:
	var new_enemy
	if (randf() >= 0.5):
		new_enemy = Shooter.instantiate()
	else:
		new_enemy = Floater.instantiate() 
		
	add_child(new_enemy)
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
