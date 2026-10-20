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
		"text": "You're out there guiding me, right? Help me keep my hands clean—I don't want to become a killer down here."
	},
	{
		"id": "wall_note_2",
		"tile": Vector2i(-5, -21),
		"text": "The way north is sealed... As we look for another path, tell me: do we spare these shadows, or strike?"
	},
	{
		"id": "wall_note_3",
		"tile": Vector2i(7, -17),
		"text": "To kill or not to kill... The silence makes me doubt my own oath. Stay with me and guide my choices."
	},
	{
		"id": "wall_note_4",
		"tile": Vector2i(-20, -3),
		"text": "Every wall looks the same, and my grip keeps tightening. Don't let me swing unless we truly have no choice."
	},
	{
		"id": "wall_note_5",
		"tile": Vector2i(-14, -20),
		"text": "The deeper we go, the harder it is to hold back. Whatever waits ahead, help me face it without losing myself."
	}
]

const PHASE_TWO_SANITY_WALL_NOTES := [
	{
		"id": "p2_wall_note_1",
		"tile": Vector2i(-2, -32),
		"text": "The walls are breathing, aren't they? I pressed my ear to the stone and heard my own voice laughing back."
	},
	{
		"id": "p2_wall_note_2",
		"tile": Vector2i(-14, -38),
		"text": "My badge feels like a piece of lead pinned to a corpse. Who am I protecting down here? There's no one left to save."
	},
	{
		"id": "p2_wall_note_3",
		"tile": Vector2i(6, -57),
		"text": "I keep wiping my hands, but the red never comes off. Maybe it's not on my skin—maybe it's behind my eyes."
	},
	{
		"id": "p2_wall_note_4",
		"tile": Vector2i(27, -55),
		"text": "The scratching in the dark sounds like a dispatcher calling my unit number over and over. Why won't you let me answer?"
	},
	{
		"id": "p2_wall_note_5",
		"tile": Vector2i(15, -40),
		"text": "Are you still out there watching me, or are you just another voice echoing inside my fractured skull?"
	},
	{
		"id": "p2_wall_note_6",
		"tile": Vector2i(-5, -26),
		"text": "I used to remember my name before the sirens faded. Now there is only the corridor, the insects, and the urge to strike."
	},
	{
		"id": "p2_wall_note_7",
		"tile": Vector2i(10, -26),
		"text": "They crawl out of the cracks like guilty thoughts. Every time I blink, the stone walls step closer."
	},
	{
		"id": "p2_wall_note_8",
		"tile": Vector2i(-19, -46),
		"text": "To serve and protect... Funny how those words rot in your mouth when the darkness stares back."
	},
	{
		"id": "p2_wall_note_9",
		"tile": Vector2i(-9, -53),
		"text": "My fingers twitch even when nothing is there. Tell me the truth—did I lose my mind before we even entered this maze?"
	},
	{
		"id": "p2_wall_note_10",
		"tile": Vector2i(8, -40),
		"text": "The stone smells like iron and gun oil. Someone wrote this note in a frenzy... Wait. That's my own handwriting."
	},
	{
		"id": "p2_wall_note_11",
		"tile": Vector2i(21, -35),
		"text": "Stop pretending we're looking for an exit. There is no precinct waiting for us above—only the bottom of the pit."
	},
	{
		"id": "p2_wall_note_12",
		"tile": Vector2i(35, -48),
		"text": "Every shadow wears a face I failed to save, or a face I put in the ground. Down here, they all look the same."
	},
	{
		"id": "p2_wall_note_13",
		"tile": Vector2i(43, -38),
		"text": "You move my legs, I swing the weapon, and the labyrinth drinks what's left of my sanity. Good partnership, isn't it?"
	},
	{
		"id": "p2_wall_note_14",
		"tile": Vector2i(28, -50),
		"text": "The ticking in my head is louder than the watch now. Let's find the note on the floor and end this nightmare."
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
	
	wall_layer.set_cell(Vector2i(-9, -15), 0, Vector2i(2, 0))
	wall_layer.set_cell(Vector2i(-9, -21), 0, Vector2i(2, 0))
	wall_layer.set_cell(Vector2i(-9, -14), 0, Vector2i(2, 1))
	wall_layer.set_cell(Vector2i(-9, -20), 0, Vector2i(2, 1))
	for bx in [-19, -18, -13, -12,]:
		wall_layer.set_cell(Vector2i(-9, bx), 0, Vector2i(2, 2))
	wall_layer.set_cell(Vector2i(-9, -11), 0, Vector2i(2, 3))
	wall_layer.set_cell(Vector2i(-9, -17), 0, Vector2i(2, 3))
	
	wall_layer.set_cell(Vector2i(6, -18), 0, Vector2i(2, 0))
	wall_layer.set_cell(Vector2i(6, -17), 0, Vector2i(2, 1))
	wall_layer.set_cell(Vector2i(6, -16), 0, Vector2i(2, 2))
	wall_layer.set_cell(Vector2i(6, -15), 0, Vector2i(2, 3))
	

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
			spawn_boss()
			await tw.finished
		if is_instance_valid(_phase_two_barrier_body):
			_phase_two_barrier_body.queue_free()
			_phase_two_barrier_body = null

func spawn_boss() -> void:
	var boss_node = get_tree().get_first_node_in_group("boss")
	
	if boss_node and is_instance_valid(boss_node):
		boss_node.visible = true
		if boss_node.has_method("activate_boss"):
			boss_node.activate_boss()
		print("¡Jefe activado globalmente mediante grupos!")

func _setup_phase_three_boss_room(root: Node, wall_layer: TileMapLayer, floor_layer: TileMapLayer) -> void:
	var is_phase_three := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_three = (GameManager.current_phase == 3)
	if not is_phase_three or not root or not wall_layer or not floor_layer:
		return

	# Find the exact walls of the Boss Room (centered around tile (3, -50))
	var min_x := -3
	for x in range(3, -15, -1):
		var c := Vector2i(x, -47)
		if wall_layer.get_cell_source_id(c) != -1 or floor_layer.get_cell_source_id(c) == -1:
			min_x = x
			break

	var max_x := 9
	for x in range(3, 20):
		var c := Vector2i(x, -47)
		if wall_layer.get_cell_source_id(c) != -1 or floor_layer.get_cell_source_id(c) == -1:
			max_x = x
			break

	var min_y := -56
	for y in range(-50, -70, -1):
		var c := Vector2i(5, y)
		if wall_layer.get_cell_source_id(c) != -1 or floor_layer.get_cell_source_id(c) == -1:
			min_y = y
			break

	var max_y := -42
	for y in range(-50, -30):
		var c := Vector2i(5, y)
		if wall_layer.get_cell_source_id(c) != -1 or floor_layer.get_cell_source_id(c) == -1:
			max_y = y
			break

	# Lock all exits along the perimeter of the Boss Room visually in wall_layer
	for y in range(min_y, max_y + 1):
		if wall_layer.get_cell_source_id(Vector2i(min_x, y)) == -1:
			wall_layer.set_cell(Vector2i(min_x, y), 0, Vector2i(0, 1))
			wall_layer.set_cell(Vector2i(min_x - 1, y), 0, Vector2i(1, 0))
		if wall_layer.get_cell_source_id(Vector2i(max_x, y)) == -1:
			wall_layer.set_cell(Vector2i(max_x, y), 0, Vector2i(2, 1))
			wall_layer.set_cell(Vector2i(max_x + 1, y), 0, Vector2i(1, 0))

	for x in range(min_x, max_x + 1):
		if wall_layer.get_cell_source_id(Vector2i(x, min_y)) == -1:
			wall_layer.set_cell(Vector2i(x, min_y), 0, Vector2i(1, 0))
			wall_layer.set_cell(Vector2i(x, min_y + 1), 0, Vector2i(1, 1))
		if wall_layer.get_cell_source_id(Vector2i(x, max_y)) == -1:
			wall_layer.set_cell(Vector2i(x, max_y - 1), 0, Vector2i(1, 0))
			wall_layer.set_cell(Vector2i(x, max_y), 0, Vector2i(1, 1))

	# Create solid StaticBody2D barriers along all 4 perimeter walls of the Boss Room so no exit can be passed
	var top_left_world := floor_layer.to_global(floor_layer.map_to_local(Vector2i(min_x, min_y)))
	var bot_right_world := floor_layer.to_global(floor_layer.map_to_local(Vector2i(max_x, max_y)))
	var room_center := (top_left_world + bot_right_world) * 0.5
	var room_w := absf(bot_right_world.x - top_left_world.x) + 256.0
	var room_h := absf(bot_right_world.y - top_left_world.y) + 256.0

	var wall_defs := [
		{"pos": Vector2(room_center.x, top_left_world.y - 60.0), "size": Vector2(room_w + 512.0, 260.0)},
		{"pos": Vector2(room_center.x, bot_right_world.y - 60.0), "size": Vector2(room_w + 512.0, 260.0)},
		{"pos": Vector2(top_left_world.x, room_center.y), "size": Vector2(260.0, room_h + 512.0)},
		{"pos": Vector2(bot_right_world.x, room_center.y), "size": Vector2(260.0, room_h + 512.0)}
	]
	for wd in wall_defs:
		var sb := StaticBody2D.new()
		sb.name = "BossRoomLockedWall"
		sb.collision_layer = 8
		sb.collision_mask = 0
		sb.global_position = wd["pos"]
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wd["size"]
		col.shape = rect
		sb.add_child(col)
		add_child(sb)

	var mid_x := int((min_x + max_x) / 2)
	var player_spawn_world := floor_layer.to_global(floor_layer.map_to_local(Vector2i(mid_x, max_y - 2)))
	var boss_spawn_world := floor_layer.to_global(floor_layer.map_to_local(Vector2i(mid_x, min_y + 5)))
	# Pistol placed on the far opposite side of the room, right behind the Final Boss
	var pistol_spawn_world := floor_layer.to_global(floor_layer.map_to_local(Vector2i(mid_x, min_y + 2))) + Vector2(0.0, 64.0)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		player.global_position = player_spawn_world
		if player.get("last_direction") != null:
			player.set("last_direction", Vector2.UP)

	# Ensure the Pistol floor object spawns in the Boss Room behind the Boss if the player doesn't already have it in inventory
	var player_has_pistol := false
	if player and player.get("inventory") != null:
		for entry in player.inventory:
			if entry is Dictionary and not entry.is_empty() and entry.has("scene") and entry["scene"] != null:
				var spath: String = entry["scene"].resource_path
				if spath.find("pistol") != -1:
					player_has_pistol = true
					break
	if not player_has_pistol:
		if get_node_or_null("/root/GameManager") and "Pistol" in GameManager.collected_item_ids:
			GameManager.collected_item_ids.erase("Pistol")
		var pistol_floor_scene := load("res://Scenes/items/pistol_floor.tscn") as PackedScene
		if pistol_floor_scene:
			var pistol_inst := pistol_floor_scene.instantiate() as Node2D
			if pistol_inst:
				pistol_inst.name = "BossRoomPistolFloor"
				pistol_inst.global_position = pistol_spawn_world
				root.add_child(pistol_inst)
		if player and player.has_method("_display_inner_thought"):
			get_tree().create_timer(0.45).timeout.connect(func():
				if is_instance_valid(player) and not player.get("is_dead"):
					player._display_inner_thought("There's something gleaming on the other side of the room behind it... I need to grab something to put this thing down. It's just self-defense, right? No one could blame me for protecting myself...", true, 6.8)
			)

	var boss_node := get_tree().get_first_node_in_group("boss") as Node2D
	if boss_node and is_instance_valid(boss_node):
		boss_node.global_position = boss_spawn_world
	spawn_boss()

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

func _spawn_phase_two_sanity_wall_notes(wall_layer: TileMapLayer, floor_layer: TileMapLayer = null) -> void:
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

	var used_wall_cells := {}
	for item in PHASE_TWO_SANITY_WALL_NOTES:
		var note_id: String = item["id"]
		if get_node_or_null("/root/GameManager") and GameManager.has_method("is_wall_note_collected"):
			if GameManager.is_wall_note_collected(note_id):
				continue

		var tcell: Vector2i = _find_nearest_valid_wall_cell(wall_layer, floor_layer, item["tile"], used_wall_cells)
		used_wall_cells[tcell] = true
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

func _is_interior_front_wall_cell(wall_layer: TileMapLayer, floor_layer: TileMapLayer, c: Vector2i) -> bool:
	if wall_layer.get_cell_source_id(c) == -1:
		return false
	var atlas := wall_layer.get_cell_atlas_coords(c)
	if not (atlas.y in [0, 1]):
		return false
	if floor_layer:
		var below := c + Vector2i(0, 1)
		if floor_layer.get_cell_source_id(below) == -1 or wall_layer.get_cell_source_id(below) != -1:
			return false
	return true

func _find_nearest_valid_wall_cell(wall_layer: TileMapLayer, floor_layer: TileMapLayer, target: Vector2i, used_cells: Dictionary) -> Vector2i:
	if not used_cells.has(target) and _is_interior_front_wall_cell(wall_layer, floor_layer, target):
		return target
	var best_cell := target
	var best_dist := 999999.0
	for r in range(1, 9):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := target + Vector2i(dx, dy)
				if used_cells.has(c):
					continue
				if _is_interior_front_wall_cell(wall_layer, floor_layer, c):
					var d := float(dx * dx + dy * dy)
					if d < best_dist:
						best_dist = d
						best_cell = c
		if best_dist < 999999.0:
			return best_cell
	return best_cell

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

	var canvas_mod := root.find_child("CanvasModulate", true, false) as CanvasModulate
	if canvas_mod:
		canvas_mod.visible = true
		canvas_mod.color = Color(0.11, 0.11, 0.13, 1.0)

	_setup_phase_one_purple_barrier(wall_layer)
	_setup_phase_two_purple_barrier(wall_layer)
	_setup_phase_two_barrier(wall_layer, floor_layer)
	_setup_phase_three_boss_room(root, wall_layer, floor_layer)
	_spawn_phase_one_sanity_wall_notes(wall_layer)
	_spawn_phase_two_sanity_wall_notes(wall_layer, floor_layer)
	_spawn_phase_two_objective_note(root, floor_layer)
	_spawn_enemies(root, floor_layer)

	var baton_node := root.get_node_or_null("baton_floor") as Node2D
	if baton_node and is_instance_valid(baton_node):
		baton_node.global_position = floor_layer.to_global(floor_layer.map_to_local(Vector2i(-2, -15)))

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

	var walkable_floor_cells := {}
	for fc in floor_layer.get_used_cells():
		if not wall_cells.has(fc):
			walkable_floor_cells[fc] = true

	# 1. Props de suelo (exclusivamente dentro de celdas de suelo caminables, nunca fuera del mapa)
	if not loaded_floor_textures.is_empty():
		var floor_cells := floor_layer.get_used_cells()
		for cell in floor_cells:
			if wall_cells.has(cell):
				continue
			# Require all 4 cardinal neighbors to be inside the map (either walkable floor or interior wall) so props never touch the outer void
			var touches_void := false
			for cardinal in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nc: Vector2i = cell + cardinal
				if floor_layer.get_cell_source_id(nc) == -1 and not wall_cells.has(nc):
					touches_void = true
					break
			if touches_void:
				continue

			var local_pos := floor_layer.map_to_local(cell)
			var world_pos := floor_layer.to_global(local_pos)

			# Evitar spawnear un obstáculo sólido encima del jugador al inicio o encima de las notas u objetivos
			var near_player := player != null and world_pos.distance_to(player.global_position) < 340.0
			var near_flashback_note := world_pos.distance_to(Vector2(-3840, -6400)) < 320.0
			var near_phase_two_note := world_pos.distance_to(Vector2(7168, -13312)) < 320.0
			var near_phase_two_barrier := world_pos.distance_to(Vector2(14720, -8576)) < 360.0
			var near_baton := world_pos.distance_to(Vector2(-384, -3712)) < 340.0
			var near_knuckles := world_pos.distance_to(Vector2(953, 483)) < 320.0
			var in_boss_room := (cell.x >= -4 and cell.x <= 10 and cell.y >= -57 and cell.y <= -41)

			if rng.randf() > spawn_chance_per_tile:
				continue

			var prop_idx := rng.randi_range(0, loaded_floor_textures.size() - 1)
			var is_solid_obstacle := (prop_idx == 5 or prop_idx == 6) # crate or broken pillar

			if is_solid_obstacle and (near_player or near_flashback_note or near_phase_two_note or near_phase_two_barrier or near_baton or near_knuckles or in_boss_room):
				prop_idx = rng.randi_range(0, 4)
				is_solid_obstacle = false

			# Solo colocar obstáculos sólidos si hay espacio libre alrededor para nunca bloquear pasillos
			if is_solid_obstacle:
				var free_neighbors := 0
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					if walkable_floor_cells.has(cell + offset):
						free_neighbors += 1
				if free_neighbors < 7:
					prop_idx = rng.randi_range(0, 4)
					is_solid_obstacle = false

			var jitter := Vector2(rng.randf_range(-38.0, 38.0), rng.randf_range(-38.0, 38.0))
			var final_pos := world_pos + jitter
			var mapped_cell := floor_layer.local_to_map(floor_layer.to_local(final_pos))
			if not walkable_floor_cells.has(mapped_cell):
				continue

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

	# 2. Props decorativas en las paredes (exclusivamente en caras interiores que dan hacia suelo caminable dentro del mapa)
	if wall_layer and not loaded_wall_textures.is_empty():
		for wcell in wall_layer.get_used_cells():
			if reserved_wall_note_cells.has(wcell):
				continue
			var atlas := wall_layer.get_cell_atlas_coords(wcell)
			# Only place wall props on interior north wall faces (atlas.y in [0, 1]) that have walkable floor directly below them
			if not (atlas.y in [0, 1]):
				continue
			if not walkable_floor_cells.has(wcell + Vector2i(0, 1)):
				continue
			if not walkable_floor_cells.has(wcell + Vector2i(-1, 1)) or not walkable_floor_cells.has(wcell + Vector2i(1, 1)):
				continue

			if rng.randf() > wall_spawn_chance:
				continue

			var w_local := wall_layer.map_to_local(wcell)
			var w_world := wall_layer.to_global(w_local)

			var jitter_x := rng.randf_range(-32.0, 32.0)
			var jitter_y := rng.randf_range(-14.0, 14.0)
			var sort_bias_y := 14.0

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
