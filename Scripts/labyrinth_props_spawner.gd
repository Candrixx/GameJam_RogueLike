class_name LabyrinthPropsSpawner
extends Node2D

const FLOOR_PROP_TEXTURES: Array[String] = [
	"res://Assets/sprites/props/prop_rubble.png",
	"res://Assets/sprites/props/prop_blood_pool.png",
	"res://Assets/sprites/props/prop_grate.png",
	"res://Assets/sprites/props/prop_bones.png",
	"res://Assets/sprites/props/prop_papers.png",
	"res://Assets/sprites/props/prop_chains.png",
	"res://Assets/sprites/props/prop_crate_broken.png",
	"res://Assets/sprites/props/prop_pillar_broken.png"
]

const WALL_PROP_TEXTURES: Array[String] = [
	"res://Assets/sprites/props/wall_shackles.png",
	"res://Assets/sprites/props/wall_crack_hole.png",
	"res://Assets/sprites/props/wall_lantern_broken.png",
	"res://Assets/sprites/props/wall_pipes.png",
	"res://Assets/sprites/props/wall_notice_torn.png",
	"res://Assets/sprites/props/wall_blood_mark.png"
]

@export var spawn_chance_per_tile: float = 0.28
@export var wall_spawn_chance: float = 0.26

func _ready() -> void:
	y_sort_enabled = true
	_ensure_solid_black_background()
	call_deferred("_populate_props")

func _ensure_solid_black_background() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var bg_layer := CanvasLayer.new()
	bg_layer.name = "SolidBlackBackgroundLayer"
	bg_layer.layer = -100
	add_child(bg_layer)

	var black_rect := ColorRect.new()
	black_rect.name = "SolidBlackRect"
	black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(black_rect)

func _populate_props() -> void:
	var root := get_tree().current_scene
	if not root:
		return

	var floor_layer := root.find_child("floor_layer", true, false) as TileMapLayer
	var wall_layer := root.find_child("wall_layer", true, false) as TileMapLayer
	if not floor_layer:
		return

	var loaded_floor_textures: Array[Texture2D] = []
	for path in FLOOR_PROP_TEXTURES:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex:
				loaded_floor_textures.append(tex)

	var loaded_wall_textures: Array[Texture2D] = []
	for path in WALL_PROP_TEXTURES:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex:
				loaded_wall_textures.append(tex)

	var wall_cells := {}
	if wall_layer:
		for wc in wall_layer.get_used_cells():
			wall_cells[wc] = true

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# 1. Props de suelo (los que no tienen colisión van en z_index = -1 para que el personaje SIEMPRE esté por encima)
	if not loaded_floor_textures.is_empty():
		var floor_cells := floor_layer.get_used_cells()
		for cell in floor_cells:
			if wall_cells.has(cell):
				continue

			var local_pos := floor_layer.map_to_local(cell)
			var world_pos := floor_layer.to_global(local_pos)

			# Evitar spawnear un obstáculo sólido encima del jugador al inicio
			var near_player := player != null and world_pos.distance_to(player.global_position) < 280.0

			if rng.randf() > spawn_chance_per_tile:
				continue

			var prop_idx := rng.randi_range(0, loaded_floor_textures.size() - 1)
			var is_solid_obstacle := (prop_idx == 6 or prop_idx == 7) # crate or broken pillar

			if is_solid_obstacle and near_player:
				prop_idx = rng.randi_range(0, 5)
				is_solid_obstacle = false

			# Solo colocar obstáculos sólidos si hay espacio libre alrededor para nunca bloquear pasillos
			if is_solid_obstacle:
				var free_neighbors := 0
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					if not wall_cells.has(cell + offset):
						free_neighbors += 1
				if free_neighbors < 7:
					prop_idx = rng.randi_range(0, 5)
					is_solid_obstacle = false

			var jitter := Vector2(rng.randf_range(-58.0, 58.0), rng.randf_range(-58.0, 58.0))
			var final_pos := world_pos + jitter

			if is_solid_obstacle:
				var body := StaticBody2D.new()
				body.global_position = final_pos
				body.collision_layer = 8 # Layer 4: Map/Obstacles
				body.collision_mask = 0
				body.y_sort_enabled = true

				var spr := Sprite2D.new()
				spr.texture = loaded_floor_textures[prop_idx]
				var sc := rng.randf_range(1.05, 1.32)
				spr.scale = Vector2(sc, sc)
				spr.flip_h = rng.randf() < 0.5
				spr.modulate = Color(0.82, 0.84, 0.82, 0.96)
				body.add_child(spr)

				var col := CollisionShape2D.new()
				var shape := CircleShape2D.new()
				shape.radius = 56.0 * sc
				col.shape = shape
				col.position = Vector2(0.0, 18.0)
				body.add_child(col)

				add_child(body)
			else:
				var spr := Sprite2D.new()
				spr.texture = loaded_floor_textures[prop_idx]
				spr.global_position = final_pos
				# z_index = -1 (igual que floor_layer y menor que character en z_index = 0)
				# para que el personaje y enemigos SIEMPRE se vean por encima de las props sin colisión
				spr.z_as_relative = false
				spr.z_index = -1
				var sc := rng.randf_range(0.95, 1.38)
				spr.scale = Vector2(sc, sc)
				spr.rotation = rng.randf_range(-0.35, 0.35)
				spr.flip_h = rng.randf() < 0.5
				spr.modulate = Color(0.80, 0.80, 0.78, 0.90)
				add_child(spr)

	# 2. Props en las paredes (distribuidas aleatoriamente sobre los muros frontales de ladrillo)
	if wall_layer and not loaded_wall_textures.is_empty():
		for wcell in wall_layer.get_used_cells():
			var atlas := wall_layer.get_cell_atlas_coords(wcell)
			# En PAREDES def.png, las filas y = 0, 1 (muro superior) y y = 4, 5 (muro inferior)
			# son las caras verticales de ladrillo donde lucen las props de pared.
			if not (atlas.y in [0, 1, 4, 5]):
				continue

			if rng.randf() > wall_spawn_chance:
				continue

			var w_local := wall_layer.map_to_local(wcell)
			var w_world := wall_layer.to_global(w_local)

			# Ajustar margen horizontal para no pisar el borde lateral de las esquinas (atlas.x == 0 o 2)
			var jitter_x := 0.0
			if atlas.x == 0:
				jitter_x = rng.randf_range(18.0, 46.0)
			elif atlas.x == 2:
				jitter_x = rng.randf_range(-46.0, -18.0)
			else:
				jitter_x = rng.randf_range(-46.0, 46.0)

			var jitter_y := rng.randf_range(-18.0, 18.0)

			# y_sort_origin de las filas 0 y 1 es 0; de las filas 4 y 5 es 100.
			# Ponemos el punto de Y-sort ligeramente por delante del muro (+14 o +114)
			# y compensamos con offset para que se dibuje encima de la pared pero detrás del jugador cuando pase frente a ella.
			var sort_bias_y := 14.0 if atlas.y in [0, 1] else 114.0

			var w_spr := Sprite2D.new()
			var w_tex := loaded_wall_textures[rng.randi_range(0, loaded_wall_textures.size() - 1)]
			w_spr.texture = w_tex
			var w_sc := rng.randf_range(1.02, 1.32)
			w_spr.scale = Vector2(w_sc, w_sc)
			w_spr.flip_h = rng.randf() < 0.5
			w_spr.global_position = w_world + Vector2(jitter_x, sort_bias_y)
			w_spr.offset = Vector2(0.0, (-sort_bias_y + jitter_y) / w_sc)
			w_spr.modulate = Color(0.84, 0.85, 0.82, 0.94)
			add_child(w_spr)
