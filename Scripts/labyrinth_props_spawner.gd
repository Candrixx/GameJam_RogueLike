class_name LabyrinthPropsSpawner
extends Node2D

const FLOOR_PROP_TEXTURES: Array[String] = [
	"res://Assets/sprites/props/prop_rubble.png",
	"res://Assets/sprites/props/prop_blood_pool.png",
	"res://Assets/sprites/props/prop_grate.png",
	"res://Assets/sprites/props/prop_bones.png",
	"res://Assets/sprites/props/prop_chains.png",
	"res://Assets/sprites/props/prop_crate_broken.png",
	"res://Assets/sprites/props/prop_pillar_broken.png"
]

const WALL_PROP_TEXTURES: Array[String] = [
	"res://Assets/sprites/props/wall_shackles.png",
	"res://Assets/sprites/props/wall_crack_hole.png",
	"res://Assets/sprites/props/wall_lantern_broken.png",
	"res://Assets/sprites/props/wall_pipes.png",
	"res://Assets/sprites/props/wall_blood_mark.png"
]

const WALL_NOTE_TEXTURE_PATH := "res://Assets/sprites/props/wall_notice_torn.png"

const PHASE_ONE_SANITY_WALL_NOTES := [
	{
		"id": "wall_note_1",
		"tile": Vector2i(3, -1),
		"text": "My badge feels heavier down here. I just need to keep my head straight and find a way out of this place."
	},
	{
		"id": "wall_note_2",
		"tile": Vector2i(-5, -21),
		"text": "The way ahead is blocked. There has to be another path. I can't fall apart now, not while I'm still on duty."
	},
	{
		"id": "wall_note_3",
		"tile": Vector2i(7, -17),
		"text": "It's too quiet. Breathe, stay calm. That's what they taught us at the academy, and right now it's all I've got."
	},
	{
		"id": "wall_note_4",
		"tile": Vector2i(-20, -3),
		"text": "Every wall looks the same. Am I walking in circles? Doesn't matter. One corner at a time."
	},
	{
		"id": "wall_note_5",
		"tile": Vector2i(-14, -20),
		"text": "The deeper I go, the harder it is to think clearly. Whatever is waiting at the end of this, I want to face it as myself."
	}
]

const PHASE_TWO_SANITY_WALL_NOTES := [
	{
		"id": "p2_wall_note_1",
		"tile": Vector2i(-2, -32),
		"text": "The air has changed. It's colder, damp, smelling like stagnant water and rust."
	},
	{
		"id": "p2_wall_note_2",
		"tile": Vector2i(-14, -38),
		"text": "I can hear them scuttling along the ceilings. Keep your flashlight raised."
	},
	{
		"id": "p2_wall_note_3",
		"tile": Vector2i(6, -57),
		"text": "Every junction feels like a trap. Stay focused on finding the exit."
	},
	{
		"id": "p2_wall_note_4",
		"tile": Vector2i(27, -55),
		"text": "Something is blocking the upper passage. There has to be a way to clear it."
	},
	{
		"id": "p2_wall_note_5",
		"tile": Vector2i(15, -40),
		"text": "My radio has been dead since the start. No backup. Just my own footsteps."
	}
]

const PHASE_ONE_EXTRA_ENEMY_POSITIONS: Array[Vector2] = [
	Vector2(384, -1408),    # North of start (#6 -> #10)
	Vector2(640, -3840),    # East side of central room (#10)
	Vector2(2432, -3584),   # Eastern corridor (#11)
	Vector2(-4480, -2432),  # Western corridor (#9)
	Vector2(-4480, 640),    # South-west corridor (#2 / #5)
	Vector2(-3200, -4736),  # North-west corridor (#14)
	Vector2(-5760, -5248),  # Far west alcove (#15)
	Vector2(-3328, -6912)   # Upper-west passage before Point 23 (#23)
]

const PHASE_TWO_ENEMY_POSITIONS: Array[Vector2i] = [
	Vector2i(-6, -15),   # North pathway (10, -25)
	Vector2i(1, -18),   # Dead-end hallway approach (20, -35)
	Vector2i(-2, -29),   # Central-east hallway (33, -36)
	Vector2i(-17, -39),  # Further east passage (44, -36)
	Vector2i(-9, -49), # North-east corridor (45, -41)
	Vector2i(15, -49), # Upper corridor (57, -50)
	Vector2i(22, -53), # Dead-end alcove (67, -41)
	Vector2i(13, -38)  # High north branch (64, -54)
]

@export var spawn_chance_per_tile: float = 0.28
@export var wall_spawn_chance: float = 0.24

var _spawned_wall_notes: Array[Node] = []

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("labyrinth_props_spawner")
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

func clear_phase_one_wall_notes() -> void:
	for n in _spawned_wall_notes:
		if is_instance_valid(n):
			n.queue_free()
	_spawned_wall_notes.clear()

func clear_phase_two_wall_notes() -> void:
	clear_phase_one_wall_notes()

func _setup_phase_one_purple_barrier(wall_layer: TileMapLayer) -> void:
	var is_phase_one := true
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_one = (GameManager.current_phase == 1)

	if not is_phase_one or not wall_layer:
		return

	# Block the corridor between central room (#10) and north passage (#18) at x = -3..-1, y = -22..-21
	for bx in [-3, -2, -1]:
		wall_layer.set_cell(Vector2i(bx, -22), 0, Vector2i(1, 0))
		wall_layer.set_cell(Vector2i(bx, -21), 0, Vector2i(1, 1))

	# Add an explicit StaticBody2D barrier to guarantee solid collision across the blocked passage
	var barrier := StaticBody2D.new()
	barrier.name = "Phase1PurpleWallBarrier"
	barrier.collision_layer = 8 # Layer 4: Map/Obstacles
	barrier.collision_mask = 0
	var b_local := wall_layer.map_to_local(Vector2i(-2, -21))
	barrier.global_position = wall_layer.to_global(b_local) + Vector2(0.0, -128.0)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(768.0, 512.0)
	col.shape = rect
	barrier.add_child(col)
	add_child(barrier)

func _setup_phase_two_purple_barrier(wall_layer: TileMapLayer) -> void:
	var is_phase_two := true
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_two = (GameManager.current_phase == 2)

	if not is_phase_two or not wall_layer:
		return

	
	wall_layer.set_cell(Vector2i(18, -41), 0, Vector2i(2, 0))
	wall_layer.set_cell(Vector2i(18, -40), 0, Vector2i(2, 1))
	for bx in [-39, -38]:
		wall_layer.set_cell(Vector2i(18, bx), 0, Vector2i(2, 2))
	wall_layer.set_cell(Vector2i(18, -37), 0, Vector2i(2, 3))
	

	# Add an explicit StaticBody2D barrier to guarantee solid collision across the blocked passage
	var barrier := StaticBody2D.new()
	barrier.name = "Phase2PurpleWallBarrier"
	barrier.collision_layer = 8 # Layer 4: Map/Obstacles
	barrier.collision_mask = 0
	var b_local := wall_layer.map_to_local(Vector2i(18, -41))
	barrier.global_position = wall_layer.to_global(b_local) + Vector2(0.0, -256.0)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(256.0, 1280.0)
	col.shape = rect
	barrier.add_child(col)
	add_child(barrier)

var _phase_two_barrier_body: StaticBody2D = null
var _phase_two_barrier_sprite: Sprite2D = null

func _setup_phase_two_barrier(wall_layer: TileMapLayer, floor_layer: TileMapLayer) -> void:
	var is_phase_two := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_two = (GameManager.current_phase == 2)

	if not is_phase_two or not wall_layer:
		return

	# If player already collected the phase 2 note, barrier is unlocked
	if get_node_or_null("/root/GameManager") and GameManager.get("phase_two_note_found") == true:
		return

	# Block the top-right passage at corridor tile (57, -34) / (56, -30) leading to the far top-right
	var barrier := StaticBody2D.new()
	barrier.name = "PhaseTwoTopRightBarrier"
	barrier.collision_layer = 8 # Layer 4: Map/Obstacles
	barrier.collision_mask = 0
	var b_pos := floor_layer.map_to_local(Vector2i(3, -41)) # World pos at tile (57, -34)
	barrier.global_position = floor_layer.to_global(b_pos)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(512.0, 512.0)
	col.shape = rect
	barrier.add_child(col)

	# Visual representation: barricade crate / rubble / wall block
	var spr := Sprite2D.new()
	if ResourceLoader.exists("res://Assets/sprites/props/prop_crate_broken.png"):
		spr.texture = load("res://Assets/sprites/props/prop_crate_broken.png")
	elif ResourceLoader.exists("res://Assets/sprites/props/prop_rubble.png"):
		spr.texture = load("res://Assets/sprites/props/prop_rubble.png")
	spr.scale = Vector2(2.4, 2.4)
	spr.modulate = Color(0.9, 0.35, 0.35, 0.98)
	spr.position = Vector2(-128.0, 0.0)
	barrier.add_child(spr)

	var detect_area := Area2D.new()
	detect_area.name = "BarrierDetectArea"
	detect_area.collision_layer = 0
	detect_area.collision_mask = 1
	var detect_col := CollisionShape2D.new()
	var detect_shape := CircleShape2D.new()
	detect_shape.radius = 340.0
	detect_col.shape = detect_shape
	detect_area.add_child(detect_col)
	barrier.add_child(detect_area)

	detect_area.body_entered.connect(func(b: Node2D):
		if b.is_in_group("player") or b.name == "character":
			if b.has_method("_display_inner_thought"):
				b._display_inner_thought("The corridor ahead is blocked by heavy debris. There has to be a way to clear it.", false, 4.2)
	)

	_phase_two_barrier_body = barrier
	_phase_two_barrier_sprite = spr
	add_child(barrier)

func unlock_phase_two_barrier() -> void:
	if _phase_two_barrier_body and is_instance_valid(_phase_two_barrier_body):
		if _phase_two_barrier_sprite:
			var tw := create_tween()
			tw.tween_property(_phase_two_barrier_sprite, "modulate:a", 0.0, 0.45)
			await tw.finished
		if is_instance_valid(_phase_two_barrier_body):
			_phase_two_barrier_body.queue_free()
			_phase_two_barrier_body = null

func _spawn_phase_one_sanity_wall_notes(wall_layer: TileMapLayer) -> void:
	if not wall_layer or not ResourceLoader.exists(WALL_NOTE_TEXTURE_PATH):
		return
	var is_phase_one := true
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_one = (GameManager.current_phase == 1)
	if not is_phase_one:
		return

	var note_tex := load(WALL_NOTE_TEXTURE_PATH) as Texture2D
	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf") as FontFile

	for item in PHASE_ONE_SANITY_WALL_NOTES:
		var note_id: String = item["id"]
		if get_node_or_null("/root/GameManager") and GameManager.has_method("is_wall_note_collected"):
			if GameManager.is_wall_note_collected(note_id):
				continue

		var tcell: Vector2i = item["tile"]
		var w_local := wall_layer.map_to_local(tcell)
		var w_world := wall_layer.to_global(w_local)

		var note_node := _InteractableWallNote.new()
		note_node.note_id = note_id
		note_node.sanity_text = item["text"]
		note_node.note_texture = note_tex
		note_node.custom_font = custom_font
		note_node.global_position = w_world + Vector2(0.0, 18.0)
		add_child(note_node)
		_spawned_wall_notes.append(note_node)

func _spawn_phase_two_sanity_wall_notes(wall_layer: TileMapLayer) -> void:
	if not wall_layer or not ResourceLoader.exists(WALL_NOTE_TEXTURE_PATH):
		return
	var is_phase_two := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_two = (GameManager.current_phase == 2)
	if not is_phase_two:
		return

	var note_tex := load(WALL_NOTE_TEXTURE_PATH) as Texture2D
	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf") as FontFile

	for item in PHASE_TWO_SANITY_WALL_NOTES:
		var note_id: String = item["id"]
		if get_node_or_null("/root/GameManager") and GameManager.has_method("is_wall_note_collected"):
			if GameManager.is_wall_note_collected(note_id):
				continue

		var tcell: Vector2i = item["tile"]
		var w_local := wall_layer.map_to_local(tcell)
		var w_world := wall_layer.to_global(w_local)

		var note_node := _InteractableWallNote.new()
		note_node.note_id = note_id
		note_node.sanity_text = item["text"]
		note_node.note_texture = note_tex
		note_node.custom_font = custom_font
		note_node.global_position = w_world + Vector2(0.0, 18.0)
		add_child(note_node)
		_spawned_wall_notes.append(note_node)

func _spawn_phase_two_objective_note(root: Node, floor_layer: TileMapLayer) -> void:
	var is_phase_two := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_two = (GameManager.current_phase == 2)
	if not is_phase_two or not root:
		return

	if get_node_or_null("/root/GameManager") and GameManager.get("phase_two_note_found") == true:
		return

	# Place the objective note at the dead end in the upper portion: tile (20, -35) -> Vector2(5248, -8832)
	var note_scene := load("res://Scenes/items/note.tscn") as PackedScene
	if note_scene:
		var note_inst := note_scene.instantiate() as Area2D
		note_inst.name = "PhaseTwoObjectiveNote"
		var local_pos = floor_layer.map_to_local(Vector2i(28, -52))
		note_inst.global_position = floor_layer.to_global(local_pos)
		root.add_child(note_inst)

func _spawn_enemies(root: Node, tile_map_layer: TileMapLayer) -> void:
	if not root:
		return
	var phase := 1
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		phase = GameManager.current_phase

	var template_enemy := root.get_node_or_null("grunt") as CharacterBody2D
	var second_enemy := root.get_node_or_null("grunt_2") as CharacterBody2D
	var flashback_note := root.get_node_or_null("Note")

	if phase == 1:
		if not template_enemy:
			return
		for pos in PHASE_ONE_EXTRA_ENEMY_POSITIONS:
			var enemy_inst := template_enemy.duplicate() as CharacterBody2D
			if enemy_inst:
				enemy_inst.global_position = pos
				root.add_child(enemy_inst)
	elif phase == 2:
		# In phase 2, clean up initial phase 1 flashback note
		if flashback_note:
			flashback_note.queue_free()
		
		var local_pos
		# Ensure template enemies are at phase 2 positions
		if template_enemy:
			local_pos = tile_map_layer.map_to_local(Vector2i(-8, -12))
			template_enemy.global_position = tile_map_layer.to_global(local_pos)
		if second_enemy:
			second_enemy.global_position = Vector2(8576, -9088)

		if template_enemy:
			for i in range(0, PHASE_TWO_ENEMY_POSITIONS.size()):
				var enemy_inst := template_enemy.duplicate() as CharacterBody2D
				if enemy_inst:
					local_pos = tile_map_layer.map_to_local(PHASE_TWO_ENEMY_POSITIONS[i])
					enemy_inst.global_position = tile_map_layer.to_global(local_pos)
					root.add_child(enemy_inst)
	else:
		if template_enemy:
			template_enemy.queue_free()
		if second_enemy:
			second_enemy.queue_free()
		if flashback_note:
			flashback_note.queue_free()

func _populate_props() -> void:
	var root := get_tree().current_scene
	if not root:
		return

	var floor_layer := root.find_child("floor_layer", true, false) as TileMapLayer
	var wall_layer := root.find_child("wall_layer", true, false) as TileMapLayer
	if not floor_layer:
		return

	_setup_phase_one_purple_barrier(wall_layer)
	_setup_phase_two_purple_barrier(wall_layer)
	_setup_phase_two_barrier(wall_layer, floor_layer)
	_spawn_phase_one_sanity_wall_notes(wall_layer)
	_spawn_phase_two_sanity_wall_notes(wall_layer)
	_spawn_phase_two_objective_note(root, floor_layer)
	_spawn_enemies(root, floor_layer)

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

	var reserved_wall_note_cells := {}
	for item in PHASE_ONE_SANITY_WALL_NOTES:
		reserved_wall_note_cells[item["tile"]] = true
	for item in PHASE_TWO_SANITY_WALL_NOTES:
		reserved_wall_note_cells[item["tile"]] = true

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

			# Evitar spawnear un obstáculo sólido encima del jugador al inicio o encima de las notas u objetivos
			var near_player := player != null and world_pos.distance_to(player.global_position) < 280.0
			var near_flashback_note := world_pos.distance_to(Vector2(-3840, -6400)) < 320.0
			var near_phase_two_note := world_pos.distance_to(Vector2(5248, -8832)) < 320.0
			var near_phase_two_barrier := world_pos.distance_to(Vector2(14720, -8576)) < 360.0

			if rng.randf() > spawn_chance_per_tile:
				continue

			var prop_idx := rng.randi_range(0, loaded_floor_textures.size() - 1)
			var is_solid_obstacle := (prop_idx == 5 or prop_idx == 6) # crate or broken pillar

			if is_solid_obstacle and (near_player or near_flashback_note or near_phase_two_note or near_phase_two_barrier):
				prop_idx = rng.randi_range(0, 4)
				is_solid_obstacle = false

			# Solo colocar obstáculos sólidos si hay espacio libre alrededor para nunca bloquear pasillos
			if is_solid_obstacle:
				var free_neighbors := 0
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					if not wall_cells.has(cell + offset):
						free_neighbors += 1
				if free_neighbors < 7:
					prop_idx = rng.randi_range(0, 4)
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
				spr.z_as_relative = false
				spr.z_index = -1
				var sc := rng.randf_range(0.95, 1.38)
				spr.scale = Vector2(sc, sc)
				spr.rotation = rng.randf_range(-0.35, 0.35)
				spr.flip_h = rng.randf() < 0.5
				spr.modulate = Color(0.80, 0.80, 0.78, 0.90)
				add_child(spr)

	# 2. Props decorativas en las paredes (sin notas de pared aleatorias)
	if wall_layer and not loaded_wall_textures.is_empty():
		for wcell in wall_layer.get_used_cells():
			if reserved_wall_note_cells.has(wcell):
				continue
			var atlas := wall_layer.get_cell_atlas_coords(wcell)
			if not (atlas.y in [0, 1, 4, 5]):
				continue

			if rng.randf() > wall_spawn_chance:
				continue

			var w_local := wall_layer.map_to_local(wcell)
			var w_world := wall_layer.to_global(w_local)

			var jitter_x := 0.0
			if atlas.x == 0:
				jitter_x = rng.randf_range(18.0, 46.0)
			elif atlas.x == 2:
				jitter_x = rng.randf_range(-46.0, -18.0)
			else:
				jitter_x = rng.randf_range(-46.0, 46.0)

			var jitter_y := rng.randf_range(-18.0, 18.0)
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


class _InteractableWallNote extends Area2D:
	var note_id: String = ""
	var sanity_text: String = ""
	var note_texture: Texture2D = null
	var custom_font: FontFile = null
	var _player_inside: bool = false
	var _prompt_label: Label = null
	var _sprite: Sprite2D = null

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 1

		_sprite = Sprite2D.new()
		_sprite.texture = note_texture
		_sprite.scale = Vector2(1.22, 1.22)
		_sprite.offset = Vector2(0.0, -14.0)
		_sprite.modulate = Color(0.95, 0.94, 0.88, 0.98)
		add_child(_sprite)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 165.0
		col.shape = shape
		col.position = Vector2(0.0, 95.0)
		add_child(col)

		_prompt_label = Label.new()
		_prompt_label.text = "[E] Read"
		_prompt_label.custom_minimum_size = Vector2(320, 56)
		_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_prompt_label.position = Vector2(-160, -125)
		_prompt_label.z_index = 20
		_prompt_label.visible = false
		if custom_font:
			_prompt_label.add_theme_font_override("font", custom_font)
		_prompt_label.add_theme_font_size_override("font_size", 46)
		_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 0.98))
		_prompt_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
		_prompt_label.add_theme_constant_override("outline_size", 11)
		_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		_prompt_label.add_theme_constant_override("shadow_offset_x", 3)
		_prompt_label.add_theme_constant_override("shadow_offset_y", 3)
		add_child(_prompt_label)

		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

	func _process(_delta: float) -> void:
		if _player_inside and Input.is_action_just_pressed("interact"):
			var player := get_tree().get_first_node_in_group("player")
			if player and (player.get("is_reading_intro") or player.get("is_dead")):
				return
			if get_node_or_null("/root/GameManager") and GameManager.has_method("mark_wall_note_collected"):
				GameManager.mark_wall_note_collected(note_id)
			if player and player.has_method("show_sanity_wall_note_thought"):
				player.show_sanity_wall_note_thought(sanity_text)
			queue_free()

	func _on_body_entered(body: Node2D) -> void:
		if body.is_in_group("player") or body.name == "character":
			_player_inside = true
			if _prompt_label:
				_prompt_label.visible = true

	func _on_body_exited(body: Node2D) -> void:
		if body.is_in_group("player") or body.name == "character":
			_player_inside = false
			if _prompt_label:
				_prompt_label.visible = false
