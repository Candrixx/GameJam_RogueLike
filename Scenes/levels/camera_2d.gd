extends Camera2D

@export var tile_map_layer: TileMapLayer

func _ready() -> void:
	if tile_map_layer:
		calculat_limites_tilemap()

func calculat_limites_tilemap() -> void:
	# Obtiene el rectángulo usado por el TileMapLayer en coordenadas locales/globales
	var rect: Rect2i = tile_map_layer.get_used_rect()
	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)
	
	# Calcula los límites en píxeles
	limit_left = int(rect.position.x * tile_size.x * tile_map_layer.scale.x)
	limit_top = int(rect.position.y * tile_size.y * tile_map_layer.scale.y)
	limit_right = int((rect.position.x + rect.size.x) * tile_size.x * tile_map_layer.scale.x)
	limit_bottom = int((rect.position.y + rect.size.y) * tile_size.y * tile_map_layer.scale.y)
