extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer



func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("click"):
		var mouse_global_pos = get_global_mouse_position()
		var mouse_local_to_tilemap = tilemap.to_local(mouse_global_pos)
		var cell: Vector2i = tilemap.local_to_map(mouse_local_to_tilemap)
		apply_growth_at_cell(cell, 1)

#This gets called whenever something dies but just demoing on tile clicks
func apply_growth_at_cell(cell: Vector2i, growth_increase: int) -> void:
	#These will need to change whenever the TileSet is updated
	var layer_index: int = 0
	var num_columns: int = 4
	var total_tiles: int = 16
	
	var source_id: int = tilemap.get_cell_source_id(cell)
	var atlas_coords: Vector2i = tilemap.get_cell_atlas_coords(cell)
	
	var current_linear_index: int = atlas_coords.y * num_columns + atlas_coords.x
	var new_linear_index: int = (current_linear_index + growth_increase) % total_tiles
	
	var new_atlas_coords_x: int = new_linear_index % num_columns
	var new_atlas_coords_y: int = new_linear_index / num_columns
	var new_atlas_coords: Vector2i = Vector2i(new_atlas_coords_x, new_atlas_coords_y)
	
	tilemap.set_cell(cell, source_id, new_atlas_coords)
