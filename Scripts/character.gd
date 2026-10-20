class_name Character
extends CharacterBody2D

const WatchOverlayScript = preload("res://Scripts/watch_overlay.gd")
const LabyrinthPropsSpawnerScript = preload("res://Scripts/labyrinth_props_spawner.gd")

const FLASHBACK_TEXT := """All my life, I’ve heard that souls are not born evil, but are corrupted over time. I thought this was true, although I never stopped asking myself: Can souls really not be born from darkness? What’s the thing that can break your spirit to the point of staining your soul?

Fame, greatness, I never wanted any of that. I didn’t even want to stand out. There was only one thing in this world that mattered to me: to serve, protect, and to care for others. I had seen what violence did to people, and I didn’t want it to do it to me.

But being a cop is inherently violent in a way, isn’t it? Does that mean that violence is inherently a part of me?"""

const FLASHBACK_PHASE_2_TEXT := """The first time I killed someone, my heart stopped for a moment. I saw the life in its body vanish and fall to the ground with a dry, cold sound. The kind that left you dazed long after. My senior coworkers tried to console me, telling stories in an attempt to show empathy. They were noble people, they were worried about me. 

But after the initial shock wore off, I didn’t feel anything. I realized then that we were worried about different things. Should I feel remorse? Anger, sadness, or something like it? 

Should we not feel satisfaction when we help others?"""

const FLASHBACK_FINAL_BOSS_TEXT := """The weight of the gun does not come from the material or the caliber, but the conscience of its owner. I see the blood on the barrel, maybe it’s what makes it feel like a feather, light and soft. My fingers tingle seconds before pulling the trigger.

It 's them or us. The ending is always the same, how you get there is just a matter of style and technique."""

const PACIFIST_MORALITY_THOUGHTS: Array[String] = [
	"Wait... do I strike, or do we slip past it? I'm a cop, not a killer—help me avoid a fight.",
	"It moves so slowly... We don't need to kill it, right? Guide me around it while we still have a choice.",
	"My hand is on my weapon... Should I hit first, or can you lead me past without bloodshed?",
	"To serve and protect... Does that mean sparing these shadows, or putting them down? What do you think?",
	"I don't want blood on my badge... Keep me moving past it, unless you think we have to strike.",
	"Kill or let live... Every shadow tests my oath. Help me choose the right path."
]

const KILL_THOUGHTS_STAGE_1: Array[String] = [
	"Another one ahead... Did we really have to kill the last one? Tell me if we hold back or strike again.",
	"There's blood on my sleeve now... Are you steering me to fight, or am I starting to want this too?",
	"To kill or not to kill... It's getting harder to tell where self-defense ends. What's your call?"
]

const KILL_THOUGHTS_STAGE_2: Array[String] = [
	"Maybe sparing them was naive... If you want me to strike again, I won't question it anymore.",
	"Why bother sneaking past when we can put them down? Go ahead—guide my hand.",
	"Each blow feels more natural than the last... You're right, partner. Hesitation only gets us killed."
]

const KILL_THOUGHTS_STAGE_3: Array[String] = [
	"No more doubts about killing. Point me at the next shadow and let's finish it together.",
	"I used to ask if we should spare them... Now I only wait for you to press the attack.",
	"Law, mercy—none of it matters down here. If it moves in our path, we put it down."
]

const WALL_NOTE_INSANITY_STAGE_1: Array[String] = [
	"There's blood on my badge... Did we really have no choice, or are you teaching me to give in?",
	"I keep asking myself if killing them is right... Why does my hand already want to swing again?"
]

const WALL_NOTE_INSANITY_STAGE_2: Array[String] = [
	"I'm tired of fighting my own conscience... If you want blood on this patrol, I'm starting to agree.",
	"Maybe mercy doesn't belong in this labyrinth. Keep leading me—I won't hold back anymore."
]

const WALL_NOTE_INSANITY_STAGE_3: Array[String] = [
	"We stopped questioning it, didn't we? You guide the steps, I deliver the blow. Nothing else matters.",
	"My hands are steady and soaked in red. You showed me the truth—striking first is the only law here."
]

# Phase 2 thoughts: more disturbed, deeper descent, talking to himself & the player
const PHASE_TWO_PACIFIST_THOUGHTS: Array[String] = [
	"These things crawl like insects... Do we still spare them, or is it getting too dangerous to hold back?",
	"We kept our hands clean before, partner. Help me slip past them again without striking.",
	"Their legs scraping the stone makes my skin crawl... Lead me around them before I lose my nerve.",
	"We haven't crossed that line yet. Stay with me—we don't have to kill to survive."
]

const PHASE_TWO_KILL_STAGE_1: Array[String] = [
	"They're faster now, and my doubts are fading... If you want it dead, just make me swing.",
	"Another target ahead. We already stained our hands—what's one more body in the dark?",
	"I'm not fighting your input anymore. Striking first is the only way through this place."
]

const PHASE_TWO_KILL_STAGE_2: Array[String] = [
	"They skitter in the dark, and we crush them. No more hesitation between you and me.",
	"My knuckles ache, but I don't want to stop. Point me at the next one, partner.",
	"The only way to silence that scraping noise is to hit first. Let's clear the corridor."
]

const PHASE_TWO_WALL_PACIFIST: Array[String] = [
	"The air is thicker here, but our hands are still clean. Help me hold on to my oath a little longer.",
	"The walls are closing in... Thank you for not making me a killer down here. Let's find the way out."
]

const PHASE_TWO_WALL_CORRUPTED: Array[String] = [
	"The paper is soaked in dark stains, just like my uniform... We've come too far to care about mercy now.",
	"Whoever wrote this was losing their grip—or maybe, like us, they finally accepted what had to be done."
]

const INVENTORY_SLOT_COUNT := 3
const INVENTORY_SCALE := 0.42
# Slot centers measured on "Inventario BASE.png" (347x720)
const INVENTORY_SLOT_CENTERS: Array[Vector2] = [Vector2(170, 145), Vector2(170, 355), Vector2(170, 566)]
const INVENTORY_ICON_BOX := Vector2(180, 145)

@export var speed = 450
var admin_speed = 1800
@export var accelaration = 35

@export var max_life: int = 3
var life: int = 3
var is_dead: bool = false
var is_invulnerable: bool = false

var kills: int = 0
var has_dealt_damage_in_phase_one: bool = false
var is_reading_intro: bool = false

var weapon_equiped: ArmaBase = null
var last_direction = Vector2.DOWN
var is_attacking = false

var _watch_overlay: CanvasLayer = null
var _hud_layer: CanvasLayer = null
var _damage_vignette_rect: TextureRect = null
var _damage_border_drawer: _DamageBorderControl = null
var _damage_flash_intensity: float = 0.0
var _injury_pulse_time: float = 0.0
var _intro_note_advance_requested: bool = false

# Organic inner thought / sanity wall note HUD
var _thought_panel: Control = null
var _thought_bg: TextureRect = null
var _inner_voice_box: PanelContainer = null
var _thought_margin: MarginContainer = null
var _thought_body_label: Label = null
var _thought_tween: Tween = null
var _note_clean_tex: Texture2D = null
var _note_blood_tex: Texture2D = null
var _morality_thought_index: int = 0
var _wall_insanity_index: int = 0
var _global_morality_cooldown: float = 0.0
var _triggered_by_flashback_note: bool = false

# Inventory: only items that can be picked up. Each entry is {} or {"scene": PackedScene, "icon": Texture2D}
var inventory: Array[Dictionary] = []
var selected_slot: int = 0
var _inv_icons: Array[TextureRect] = []
var _inv_select_rect: TextureRect = null

#Dicionario de sonidos relacionados al personaje
var sounds = {
	"Walk_Side": {
		2: preload("res://Assets/Music/Pisada_unica.mp3")
	},
	"Walk_Front": {
		2: preload("res://Assets/Music/Pisada_unica.mp3")
	},
	"Walk_Back": {
		2: preload("res://Assets/Music/Pisada_unica.mp3")
	}
}

var admin_mode: bool = false
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var point_equipment: Marker2D = $EquipmentPoint
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AnimatedSprite2D/AudioStreamPlayer2D

var _unarmed_weapon: ArmaBase = null
var _stone_steps: Array[AudioStreamWAV] = []
var _step_index: int = 0
var _footstep_timer: float = 0.0

func _ready() -> void:
	life = max_life
	add_to_group("player")
	_setup_shoe_footsteps()
	_setup_pistol_animations()
	_setup_unarmed_hitbox()

	if get_node_or_null("/root/GameManager") and GameManager.get("saved_inventory") != null:
		inventory = GameManager.saved_inventory
		selected_slot = GameManager.saved_selected_slot
		GameManager.saved_inventory = null
	else:
		inventory.clear()
		for i in INVENTORY_SLOT_COUNT:
			inventory.append({})

	while inventory.size() < INVENTORY_SLOT_COUNT:
		inventory.append({})
	if inventory.size() > INVENTORY_SLOT_COUNT:
		inventory.resize(INVENTORY_SLOT_COUNT)

	_setup_labyrinth_props_and_void()
	_setup_watch_overlay()
	_setup_damage_indicator()
	_setup_thought_hud()
	_setup_inventory_hud()
	select_inventory_slot(selected_slot)
	_update_phase_gameplay_music()
	call_deferred("_show_intro_notes")

func _update_phase_gameplay_music() -> void:
	if not get_node_or_null("/root/GameManager") or not GameManager.has_method("play_music"):
		return
	var cur_phase := 1
	if GameManager.get("current_phase") != null:
		cur_phase = int(GameManager.current_phase)
	if cur_phase == 3:
		GameManager.play_music(GameManager.MUSIC_PELIGRO)
	else:
		GameManager.play_music(GameManager.MUSIC_PELIGRO_3)

func _setup_shoe_footsteps() -> void:
	if audio_player:
		if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
			audio_player.bus = GameManager.ensure_labyrinth_echo_bus()
		audio_player.volume_db = -3.5
		audio_player.max_distance = 4000.0
	_stone_steps.clear()
	# 4 subtle variations of dress shoes stepping on cold stone slabs (alternating left/right heel + sole)
	_stone_steps.append(_generate_stone_footstep_wav(210.0, 920.0, 1480.0, 101))
	_stone_steps.append(_generate_stone_footstep_wav(195.0, 860.0, 1390.0, 202))
	_stone_steps.append(_generate_stone_footstep_wav(218.0, 950.0, 1540.0, 303))
	_stone_steps.append(_generate_stone_footstep_wav(190.0, 830.0, 1340.0, 404))

func _generate_stone_footstep_wav(body_freq: float, stone_mid_freq: float, stone_click_freq: float, seed_val: int) -> AudioStreamWAV:
	# Synthesizes a crisp, realistic footstep on a stone floor (heel strike clack + sole roll on stone)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var mix_rate := 22050
	var duration := 0.11
	var total_samples := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var bp_fast := 0.0
	var bp_slow := 0.0
	for i in range(total_samples):
		var t := float(i) / float(mix_rate)

		# Band-passed stone surface texture (strictly gated by the impact envelopes so there is zero background noise)
		var raw := rng.randf_range(-1.0, 1.0)
		bp_fast += 0.36 * (raw - bp_fast)
		bp_slow += 0.09 * (bp_fast - bp_slow)
		var stone_grit := bp_fast - bp_slow

		# 1. Heel strike on hard stone slab (0 ms .. 35 ms)
		var heel_env := exp(-t * 115.0)
		var heel_body := sin(TAU * (body_freq * exp(-t * 18.0)) * t) * 0.52
		var heel_clack := (
			sin(TAU * (stone_mid_freq * exp(-t * 28.0)) * t) * 0.38
			+ sin(TAU * (stone_click_freq * exp(-t * 42.0)) * t) * 0.24
			+ stone_grit * 0.68
		) * exp(-t * 155.0)
		var heel := (heel_body + heel_clack) * heel_env

		# 2. Sole contact on stone 24 ms after heel strike
		var sole_t := maxf(0.0, t - 0.024)
		var sole_env := exp(-sole_t * 135.0) if t >= 0.024 else 0.0
		var sole_contact := (
			sin(TAU * (body_freq * 0.85 * exp(-sole_t * 20.0)) * sole_t) * 0.34
			+ sin(TAU * (stone_mid_freq * 0.78 * exp(-sole_t * 32.0)) * sole_t) * 0.28
			+ stone_grit * 0.55
		) * sole_env

		var sample := heel + sole_contact * 0.82
		var pcm := int(clampf(sample * 0.92, -1.0, 1.0) * 26500.0)
		bytes.encode_s16(i * 2, pcm)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _load_fresh_texture(sheet_path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(sheet_path)
	if FileAccess.file_exists(global_path):
		var img := Image.load_from_file(global_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(sheet_path):
		return load(sheet_path) as Texture2D
	return null

func _setup_pistol_animations() -> void:
	if not animated_sprite_2d or not animated_sprite_2d.sprite_frames:
		return
	var sf := animated_sprite_2d.sprite_frames.duplicate() as SpriteFrames
	var anim_defs := {}

	var pistol_sheet := _load_fresh_texture("res://Assets/sprites/Animation_Character_Pistol.png")
	if pistol_sheet:
		var frames_list: Array[AtlasTexture] = []
		for i in range(6):
			var at := AtlasTexture.new()
			at.atlas = pistol_sheet
			at.region = Rect2(i * 512, 0, 512, 512)
			frames_list.append(at)

		anim_defs["Attack_Pistol_Front"] = {"frames": [frames_list[0], frames_list[1], frames_list[0]], "speed": 10.0, "loop": false}
		anim_defs["Attack_Pistol_Side"] = {"frames": [frames_list[2], frames_list[3], frames_list[2]], "speed": 10.0, "loop": false}
		anim_defs["Attack_Pistol_Back"] = {"frames": [frames_list[4], frames_list[5], frames_list[4]], "speed": 10.0, "loop": false}
		anim_defs["Idle_Pistol_Front"] = {"frames": [frames_list[0]], "speed": 5.0, "loop": true}
		anim_defs["Idle_Pistol_Side"] = {"frames": [frames_list[2]], "speed": 5.0, "loop": true}
		anim_defs["Idle_Pistol_Back"] = {"frames": [frames_list[4]], "speed": 5.0, "loop": true}

	for aname in anim_defs.keys():
		if sf.has_animation(aname):
			sf.clear(aname)
		else:
			sf.add_animation(aname)
		sf.set_animation_speed(aname, anim_defs[aname]["speed"])
		sf.set_animation_loop(aname, anim_defs[aname]["loop"])
		for ftex in anim_defs[aname]["frames"]:
			sf.add_frame(aname, ftex)
	animated_sprite_2d.sprite_frames = sf

func _setup_unarmed_hitbox() -> void:
	if not point_equipment:
		return
	var base_scene := load("res://Scenes/items/brass_knuckles.tscn") as PackedScene
	if base_scene:
		_unarmed_weapon = base_scene.instantiate() as ArmaBase
		if _unarmed_weapon:
			_unarmed_weapon.name = "UnarmedHitbox"
			_unarmed_weapon.damage = 10
			_unarmed_weapon.knockback_force = 260.0
			point_equipment.add_child(_unarmed_weapon)
			_unarmed_weapon.position = Vector2.ZERO
			_unarmed_weapon.rotation = 0

func _process(delta: float) -> void:
	_update_damage_indicator(delta)
	if _global_morality_cooldown > 0.0:
		_global_morality_cooldown = maxf(0.0, _global_morality_cooldown - delta)

var temp_speed = 0

func _physics_process(delta: float) -> void:
	if is_reading_intro:
		return
	if Input.is_action_just_pressed("admind_mode"):
		admin_mode = not admin_mode
		if admin_mode:
			temp_speed = speed
			speed = admin_speed
		else:
			speed = temp_speed
		_toggle_admin_mode(admin_mode)
		
	var attack = Input.is_action_just_pressed("attack")
	
	if attack and not is_dead and not is_attacking:
		if not weapon_equiped:
			# Auto-select first slot with a weapon if available, or punch unarmed
			for i in INVENTORY_SLOT_COUNT:
				if not inventory[i].is_empty():
					select_inventory_slot(i)
					break
		if weapon_equiped:
			attacking(weapon_equiped.weapon_name)
		else:
			attacking("Knuckles")

	if is_attacking or is_dead:
		return
	
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.lerp(speed * direction, delta * accelaration)
		last_direction = direction
		if point_equipment:
			point_equipment.rotation = direction.angle() - PI / 2
	else:
		velocity = Vector2.ZERO
	
	if velocity != Vector2.ZERO:
		play_animation(last_direction, "Walk")
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = 0.31
			if audio_player and not _stone_steps.is_empty():
				audio_player.stream = _stone_steps[_step_index % _stone_steps.size()]
				audio_player.pitch_scale = randf_range(0.96, 1.05)
				audio_player.play()
				_step_index += 1
	else:
		_footstep_timer = 0.02
		play_animation(last_direction, "Idle")
	move_and_slide()

func _toggle_admin_mode(enabled: bool) -> void:
	if enabled:
		print("Modo Admin ACTIVADO (Noclip)")
		# Desactivamos la colisión física para atravesar paredes
		if collision_shape:
			collision_shape.disabled = true
	else:
		print("Modo Admin DESACTIVADO")
		# Reactivamos la colisión normal
		if collision_shape:
			collision_shape.disabled = false

func play_animation(direction: Vector2, prefix: String):
	var animation_to_play = ""
	var holding_pistol := (weapon_equiped != null and weapon_equiped.weapon_name == "Pistol")
	var actual_prefix := "Idle_Pistol" if (prefix == "Idle" and holding_pistol and animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("Idle_Pistol_Front")) else prefix

	if absf(direction.x) > absf(direction.y) and absf(direction.x) > 0.01:
		animated_sprite_2d.flip_h = direction.x < 0
		animation_to_play = actual_prefix + "_Side"
	elif direction.y < 0:
		animated_sprite_2d.flip_h = false
		animation_to_play = actual_prefix + "_Back"
	elif direction.y >= 0:
		animated_sprite_2d.flip_h = false
		animation_to_play = actual_prefix + "_Front"
		
	if animated_sprite_2d.animation != animation_to_play:
		animated_sprite_2d.play(animation_to_play)

func attacking(suffix: String) -> void:
	is_attacking = true
	var fire_dir: Vector2 = last_direction.normalized()
	if fire_dir.length_squared() < 0.001:
		fire_dir = Vector2.UP
	if suffix == "Pistol" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length_squared() > 16.0:
			fire_dir = to_mouse.normalized()
			last_direction = fire_dir
	if point_equipment:
		point_equipment.rotation = fire_dir.angle() - PI / 2
	var active_hitbox: ArmaBase = weapon_equiped if weapon_equiped else _unarmed_weapon
	if suffix == "Pistol":
		var shot_dmg: int = active_hitbox.damage if active_hitbox else 35
		_play_pistol_shot_sfx()
		_spawn_pistol_bullet(fire_dir, shot_dmg)
	elif active_hitbox:
		active_hitbox.enable_hitbox()
	var anim_name := "Attack_" + suffix
	if suffix == "Pistol" and animated_sprite_2d.sprite_frames:
		if absf(fire_dir.x) >= absf(fire_dir.y):
			animated_sprite_2d.flip_h = fire_dir.x < 0
			anim_name = "Attack_Pistol_Side"
		elif fire_dir.y < 0:
			animated_sprite_2d.flip_h = false
			anim_name = "Attack_Pistol_Back"
		else:
			animated_sprite_2d.flip_h = false
			anim_name = "Attack_Pistol_Front"
	else:
		if absf(fire_dir.x) > 0.15:
			animated_sprite_2d.flip_h = fire_dir.x < 0
	if animated_sprite_2d.sprite_frames and not animated_sprite_2d.sprite_frames.has_animation(anim_name):
		anim_name = "Attack_Knuckles"
	animated_sprite_2d.play(anim_name)
	# Wait for attack animation or safe fallback timeout so is_attacking never gets stuck
	var max_wait := 0.26 if suffix == "Pistol" else 0.45
	var elapsed := 0.0
	while animated_sprite_2d.is_playing() and animated_sprite_2d.animation == anim_name and elapsed < max_wait:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	is_attacking = false
	if active_hitbox:
		active_hitbox.disable_hitbox()

func _play_pistol_shot_sfx() -> void:
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.volume_db = -3.0
	if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
		sfx_player.bus = GameManager.ensure_labyrinth_echo_bus()
	add_child(sfx_player)
	var mix_rate := 22050
	var duration := 0.16
	var total_samples := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	for i in range(total_samples):
		var t := float(i) / float(mix_rate)
		var env := exp(-t * 32.0)
		var bang := (randf() * 2.0 - 1.0) * 0.75 + sin(TAU * 145.0 * exp(-t * 18.0) * t) * 0.55
		var s_val := int(clampf(bang * env, -1.0, 1.0) * 28000.0)
		bytes.encode_s16(i * 2, s_val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	sfx_player.stream = wav
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _spawn_pistol_bullet(dir: Vector2, shot_damage: int) -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
	var muzzle_pos := global_position + Vector2(0, -35) + dir * 75.0

	# Muzzle flash
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(36, 0), Vector2(0, 14), Vector2(-10, 0)
	])
	flash.color = Color(1.0, 0.88, 0.42, 0.95)
	flash.global_position = muzzle_pos
	flash.rotation = dir.angle()
	flash.z_index = 25
	parent_node.add_child(flash)
	var f_tw := flash.create_tween()
	f_tw.tween_property(flash, "scale", Vector2(1.4, 0.3), 0.07)
	f_tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.07)
	f_tw.tween_callback(flash.queue_free)

	var bullet := _PistolBullet.new()
	bullet.global_position = muzzle_pos
	bullet.direction = dir
	bullet.damage = shot_damage
	bullet.shooter = self
	parent_node.add_child(bullet)

func equip_weapon(new_weapon: PackedScene):
	if weapon_equiped:
		weapon_equiped.queue_free()
		
	weapon_equiped = new_weapon.instantiate() as ArmaBase
	if weapon_equiped:
		point_equipment.add_child(weapon_equiped)
		weapon_equiped.position = Vector2.ZERO
		weapon_equiped.rotation = 0

func unequip_weapon() -> void:
	if weapon_equiped:
		weapon_equiped.queue_free()
	weapon_equiped = null

# Called by pickable floor items. Returns false when the inventory is full.
func add_to_inventory(item_scene: PackedScene, icon: Texture2D) -> bool:
	if item_scene == null:
		return false
	var target := -1
	if inventory[selected_slot].is_empty():
		target = selected_slot
	else:
		for i in INVENTORY_SLOT_COUNT:
			if inventory[i].is_empty():
				target = i
				break
	if target == -1:
		target = selected_slot
	inventory[target] = {"scene": item_scene, "icon": icon}
	selected_slot = target
	equip_weapon(item_scene)
	_refresh_inventory_hud()
	return true

func select_inventory_slot(index: int) -> void:
	index = wrapi(index, 0, INVENTORY_SLOT_COUNT)
	if is_dead:
		return
	selected_slot = index
	var entry: Dictionary = inventory[index]
	if entry.is_empty():
		unequip_weapon()
	else:
		equip_weapon(entry["scene"])
	_refresh_inventory_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_reading_intro or is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode if event.keycode != 0 else event.physical_keycode
		match k:
			KEY_1:
				select_inventory_slot(0)
			KEY_2:
				select_inventory_slot(1)
			KEY_3:
				select_inventory_slot(2)
			KEY_UP, KEY_LEFT:
				select_inventory_slot(selected_slot - 1)
			KEY_DOWN, KEY_RIGHT:
				select_inventory_slot(selected_slot + 1)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_inventory_slot(selected_slot - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_inventory_slot(selected_slot + 1)

func _setup_inventory_hud() -> void:
	if not _hud_layer:
		return
	var base_tex: Texture2D = load("res://Assets/inventory/Inventario BASE.png") if ResourceLoader.exists("res://Assets/inventory/Inventario BASE.png") else null
	var sel_tex: Texture2D = load("res://Assets/inventory/Inventario SELECCION.png") if ResourceLoader.exists("res://Assets/inventory/Inventario SELECCION.png") else null
	var base_size := base_tex.get_size() if base_tex else Vector2(347, 720)

	var root := Control.new()
	root.name = "InventoryHUD"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	root.offset_left = -(base_size.x * INVENTORY_SCALE + 24.0)
	root.offset_top = -base_size.y * INVENTORY_SCALE * 0.5
	root.offset_right = root.offset_left + base_size.x
	root.offset_bottom = root.offset_top + base_size.y
	root.scale = Vector2(INVENTORY_SCALE, INVENTORY_SCALE)
	_hud_layer.add_child(root)

	var bg := TextureRect.new()
	bg.texture = base_tex
	bg.size = base_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	for i in INVENTORY_SLOT_COUNT:
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = INVENTORY_ICON_BOX
		icon.position = INVENTORY_SLOT_CENTERS[i] - INVENTORY_ICON_BOX * 0.5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
		_inv_icons.append(icon)

	_inv_select_rect = TextureRect.new()
	_inv_select_rect.texture = sel_tex
	_inv_select_rect.size = sel_tex.get_size() if sel_tex else Vector2(281, 234)
	_inv_select_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_inv_select_rect)

	_refresh_inventory_hud()

func _refresh_inventory_hud() -> void:
	if _inv_icons.is_empty():
		return
	for i in INVENTORY_SLOT_COUNT:
		var entry: Dictionary = inventory[i]
		_inv_icons[i].texture = null if entry.is_empty() else entry.get("icon")
		_inv_icons[i].modulate = Color.WHITE if i == selected_slot else Color(0.75, 0.75, 0.72, 0.85)
	if _inv_select_rect:
		_inv_select_rect.position = INVENTORY_SLOT_CENTERS[selected_slot] - _inv_select_rect.size * 0.5

func _get_total_kills() -> int:
	if get_node_or_null("/root/GameManager") and GameManager.get("kill_count") != null:
		return maxi(kills, int(GameManager.kill_count))
	return kills

func add_kill() -> void:
	kills += 1
	if get_node_or_null("/root/GameManager") and GameManager.has_method("add_kill"):
		GameManager.add_kill()
	var total := _get_total_kills()
	print("Enemies defeated: ", total, " | Genocide route active")
	_global_morality_cooldown = 3.5

	var is_p2 := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_p2 = (GameManager.current_phase == 2)

	if is_p2:
		if total <= 1:
			_display_inner_thought("I killed it... Did we really have to strike, or are we giving up on mercy now?", false, 4.8)
		elif total <= 3:
			_display_inner_thought("Another one crushed. You didn't hesitate, and neither did my hand.", true, 4.8)
		elif total <= 5:
			_display_inner_thought("Four, five... I stopped asking if we should spare them. Just point me at the next one.", true, 5.0)
		else:
			_display_inner_thought("Every corridor smells of blood. You and I don't need excuses to kill anymore.", true, 5.0)
	else:
		if total == 1:
			_display_inner_thought("I killed it... Did we really have to do that, or could you have led me around it?", false, 4.8)
		elif total == 2:
			_display_inner_thought("Two down... I'm still telling myself it's self-defense, but you're making it feel too easy.", false, 4.8)
		elif total == 3:
			_display_inner_thought("Three... I'm stopping the questions now. If you think they need to die, I'll swing.", true, 4.8)
		elif total == 4:
			_display_inner_thought("Four... Why was I ever afraid to strike? Keep pushing me forward, partner.", true, 5.0)
		else:
			_display_inner_thought("Another one gone. We don't need excuses anymore—just you, me, and the next target.", true, 5.0)

func trigger_enemy_morality_thought() -> void:
	if is_dead or is_reading_intro or _global_morality_cooldown > 0.0:
		return
	_global_morality_cooldown = 6.5

	var total := _get_total_kills()
	var line := ""
	var is_p2 := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_p2 = (GameManager.current_phase == 2)

	if is_p2:
		if total <= 0:
			line = PHASE_TWO_PACIFIST_THOUGHTS[_morality_thought_index % PHASE_TWO_PACIFIST_THOUGHTS.size()]
		elif total <= 3:
			line = PHASE_TWO_KILL_STAGE_1[_morality_thought_index % PHASE_TWO_KILL_STAGE_1.size()]
		else:
			line = PHASE_TWO_KILL_STAGE_2[_morality_thought_index % PHASE_TWO_KILL_STAGE_2.size()]
	else:
		if total <= 0:
			line = PACIFIST_MORALITY_THOUGHTS[_morality_thought_index % PACIFIST_MORALITY_THOUGHTS.size()]
		elif total <= 2:
			line = KILL_THOUGHTS_STAGE_1[_morality_thought_index % KILL_THOUGHTS_STAGE_1.size()]
		elif total <= 4:
			line = KILL_THOUGHTS_STAGE_2[_morality_thought_index % KILL_THOUGHTS_STAGE_2.size()]
		else:
			line = KILL_THOUGHTS_STAGE_3[_morality_thought_index % KILL_THOUGHTS_STAGE_3.size()]

	_morality_thought_index += 1
	var is_bloody := (total >= 3) if not is_p2 else (total >= 1)
	_display_inner_thought(line, is_bloody, 4.4)

func show_sanity_wall_note_thought(base_text: String) -> void:
	if is_dead:
		return
	_global_morality_cooldown = 5.0
	var total := _get_total_kills()
	var final_text := base_text
	var is_p2 := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_p2 = (GameManager.current_phase == 2)

	if is_p2:
		# In Phase 2, each wall note shows its unique descent-into-madness text directly
		final_text = base_text
		_wall_insanity_index += 1
	else:
		if total >= 5:
			final_text = WALL_NOTE_INSANITY_STAGE_3[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_3.size()]
			_wall_insanity_index += 1
		elif total >= 3:
			final_text = WALL_NOTE_INSANITY_STAGE_2[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_2.size()]
			_wall_insanity_index += 1
		elif total >= 1:
			final_text = WALL_NOTE_INSANITY_STAGE_1[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_1.size()]
			_wall_insanity_index += 1

	var is_bloody := true if is_p2 else (total >= 3)
	_display_wall_note_text(final_text, is_bloody, 5.8)

func trigger_flashback_note_drain() -> void:
	if is_dead:
		return
	_triggered_by_flashback_note = true
	_clear_phase_one_wall_notes()
	if _watch_overlay and _watch_overlay.has_method("trigger_rapid_drain_to_zero"):
		_watch_overlay.trigger_rapid_drain_to_zero()
	else:
		die_from_timeout()

func _clear_phase_one_wall_notes() -> void:
	var spawner := get_tree().get_first_node_in_group("labyrinth_props_spawner")
	if spawner:
		if spawner.has_method("clear_phase_one_wall_notes"):
			spawner.clear_phase_one_wall_notes()
		if spawner.has_method("clear_phase_two_wall_notes"):
			spawner.clear_phase_two_wall_notes()

func register_damage_dealt(_amount: int) -> void:
	has_dealt_damage_dealt_in_phase_one()

func has_dealt_damage_dealt_in_phase_one() -> void:
	has_dealt_damage_in_phase_one = true

func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable or is_reading_intro:
		return

	life = maxi(0, life - amount)
	_damage_flash_intensity = 1.0
	_update_damage_indicator(0.0)
	print("Player took damage! Life: ", life)

	if life <= 0:
		die()
	else:
		# Brief flash / i-frame window so player doesn't instantly die on touch
		_start_invulnerability(0.8)

func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	
	var tween = create_tween().set_loops(4)
	var flash_color = Color(1.0, 0.2, 0.2, 0.4)
	var normal_color = Color.WHITE
	var step_time = duration / 8.0

	tween.tween_property(animated_sprite_2d, "modulate", flash_color, step_time)
	tween.tween_property(animated_sprite_2d, "modulate", normal_color, step_time)
	
	await get_tree().create_timer(duration).timeout
	
	is_invulnerable = false
	animated_sprite_2d.modulate = Color.WHITE

func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	_clear_phase_one_wall_notes()

	if _thought_panel:
		_thought_panel.visible = false

	if _watch_overlay and _watch_overlay.has_method("force_close"):
		_watch_overlay.force_close()

	if weapon_equiped and weapon_equiped.has_method("disable_hitbox"):
		weapon_equiped.disable_hitbox()
	if _unarmed_weapon and _unarmed_weapon.has_method("disable_hitbox"):
		_unarmed_weapon.disable_hitbox()

	animated_sprite_2d.play("Die")
	await animated_sprite_2d.animation_finished

	await get_tree().create_timer(0.35).timeout
	await _show_enemy_death_note()

	if get_node_or_null("/root/GameManager"):
		if GameManager.get("current_phase") == 3:
			# If killed by the Boss in Phase 3, respawn right in the Boss Room and keep inventory
			GameManager.saved_inventory = inventory.duplicate(true)
			GameManager.saved_selected_slot = selected_slot
		elif GameManager.has_method("reset_to_phase_one"):
			GameManager.reset_to_phase_one()
		elif GameManager.has_method("reset_kills"):
			GameManager.reset_kills()
	get_tree().reload_current_scene()

func _show_enemy_death_note() -> void:
	if get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
		GameManager.play_music(GameManager.MUSIC_TENSA_CALMA)
	is_reading_intro = true
	var prev_process_mode := process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var layer := CanvasLayer.new()
	layer.layer = 122
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.focus_mode = Control.FOCUS_ALL
	layer.add_child(root)
	root.grab_focus()

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.01, 0.015, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	# Native 1:1 non-deformed size of nota_sangre.png is 1040 x 529 -> displayed at 1144 x 582 (exact 1.1x uniform aspect ratio)
	var note_w := 1144.0
	var note_h := 582.0

	var note_tex: Texture2D = _load_fresh_texture("res://Assets/nota_sangre.png")
	if not note_tex:
		note_tex = _load_fresh_texture("res://Assets/nota_limpia.png")

	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	var note_holder := Control.new()
	note_holder.custom_minimum_size = Vector2(note_w, note_h)
	note_holder.pivot_offset = Vector2(note_w * 0.5, note_h * 0.5)
	note_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(note_holder)

	var note_bg := TextureRect.new()
	note_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_bg.texture = note_tex
	note_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_holder.add_child(note_bg)

	# Generous margins inside the bloody torn edges so the text fits cleanly in the center paper area
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 150)
	margin.add_theme_constant_override("margin_right", 150)
	margin.add_theme_constant_override("margin_top", 95)
	margin.add_theme_constant_override("margin_bottom", 80)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_holder.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer_top)

	var msg_lbl := Label.new()
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.text = "Don’t let this happen again!"
	if custom_font:
		msg_lbl.add_theme_font_override("font", custom_font)
	msg_lbl.add_theme_font_size_override("font_size", 50)
	msg_lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 0.96))
	msg_lbl.add_theme_color_override("font_outline_color", Color(0.62, 0.64, 0.56, 0.45))
	msg_lbl.add_theme_constant_override("outline_size", 2)
	vbox.add_child(msg_lbl)

	var line_div := ColorRect.new()
	line_div.custom_minimum_size = Vector2(460.0, 2.0)
	line_div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line_div.color = Color(0.12, 0.12, 0.10, 0.55)
	line_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(line_div)

	var spacer_bot := Control.new()
	spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer_bot)

	var sub_lbl := Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.text = "[ Press any key or Click to restart ]"
	if custom_font:
		sub_lbl.add_theme_font_override("font", custom_font)
	sub_lbl.add_theme_font_size_override("font_size", 22)
	sub_lbl.add_theme_color_override("font_color", Color(0.14, 0.14, 0.12, 0.85))
	vbox.add_child(sub_lbl)

	root.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_intro_note_advance_requested = true
	)

	note_holder.modulate.a = 0.0
	note_holder.scale = Vector2(0.94, 0.94)
	var t_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	t_in.tween_property(note_holder, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_SINE)
	t_in.tween_property(note_holder, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t_in.finished

	await _wait_for_note_advance()

	var t_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t_out.tween_property(root, "modulate:a", 0.0, 0.22)
	await t_out.finished

	layer.queue_free()
	get_tree().paused = false
	process_mode = prev_process_mode
	is_reading_intro = false

func die_from_timeout() -> void:
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	life = 0
	_damage_flash_intensity = 1.0
	_update_damage_indicator(0.0)
	velocity = Vector2.ZERO
	_clear_phase_one_wall_notes()

	if _thought_panel:
		_thought_panel.visible = false

	# Close watch overlay so the player sees the character dying animation
	if _watch_overlay and _watch_overlay.has_method("force_close"):
		_watch_overlay.force_close()

	if weapon_equiped and weapon_equiped.has_method("disable_hitbox"):
		weapon_equiped.disable_hitbox()
	if _unarmed_weapon and _unarmed_weapon.has_method("disable_hitbox"):
		_unarmed_weapon.disable_hitbox()

	animated_sprite_2d.modulate = Color.WHITE
	animated_sprite_2d.play("Die")
	await animated_sprite_2d.animation_finished

	await get_tree().create_timer(0.6).timeout

	# Only advance to the next phase if the player collected the Flashback Note.
	# Otherwise (time ran out without grabbing the flashback note), show "Don't let this happen again!" and reset to Phase 1 from 0.
	if _triggered_by_flashback_note:
		if get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
			GameManager.play_music(GameManager.MUSIC_TENSA_CALMA)
		var cur_phase := 1
		if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
			cur_phase = int(GameManager.current_phase)
		if cur_phase == 2:
			await _show_timeout_flashback(FLASHBACK_PHASE_2_TEXT)
			if get_node_or_null("/root/GameManager") and GameManager.has_method("advance_to_phase_three"):
				GameManager.advance_to_phase_three()
				GameManager.saved_inventory = inventory.duplicate(true)
				GameManager.saved_selected_slot = selected_slot
		else:
			await _show_timeout_flashback(FLASHBACK_TEXT)
			if get_node_or_null("/root/GameManager") and GameManager.has_method("advance_to_phase_two"):
				GameManager.advance_to_phase_two()
				GameManager.saved_inventory = inventory.duplicate(true)
				GameManager.saved_selected_slot = selected_slot
	else:
		await _show_enemy_death_note()
		if get_node_or_null("/root/GameManager"):
			if GameManager.get("current_phase") == 3:
				GameManager.saved_inventory = inventory.duplicate(true)
				GameManager.saved_selected_slot = selected_slot
			elif GameManager.has_method("reset_to_phase_one"):
				GameManager.reset_to_phase_one()
			elif GameManager.has_method("reset_kills"):
				GameManager.reset_kills()
	get_tree().reload_current_scene()

func show_final_boss_victory_flashback() -> void:
	if is_dead:
		return
	is_invulnerable = true
	is_reading_intro = true
	is_attacking = false
	velocity = Vector2.ZERO
	if _thought_panel:
		_thought_panel.visible = false
	if _watch_overlay:
		_watch_overlay.countdown_started = false
		if _watch_overlay.has_method("force_close"):
			_watch_overlay.force_close()

	if get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
		GameManager.play_music(GameManager.MUSIC_CAMINO_BUENO)

	await get_tree().create_timer(0.9).timeout
	await _show_timeout_flashback(FLASHBACK_FINAL_BOSS_TEXT)

	if get_node_or_null("/root/GameManager"):
		if GameManager.has_method("reset_to_phase_one"):
			GameManager.reset_to_phase_one()
		GameManager.open_credits_on_menu = true
	if ResourceLoader.exists("res://Scenes/ui/homescreen.tscn"):
		get_tree().change_scene_to_file("res://Scenes/ui/homescreen.tscn")
	elif ResourceLoader.exists("res://Scenes/UI/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
	else:
		get_tree().reload_current_scene()

func _show_timeout_flashback(custom_text: String = "") -> void:
	if _hud_layer:
		_hud_layer.visible = false

	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.modulate.a = 0.0
	layer.add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.03, 0.97)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(960, 0)
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	var text_lbl := Label.new()
	text_lbl.custom_minimum_size = Vector2(960, 0)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.text = custom_text if custom_text != "" else FLASHBACK_TEXT
	if custom_font:
		text_lbl.add_theme_font_override("font", custom_font)
	text_lbl.add_theme_font_size_override("font_size", 26)
	text_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.80, 0.96))
	text_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	text_lbl.add_theme_constant_override("shadow_offset_x", 2)
	text_lbl.add_theme_constant_override("shadow_offset_y", 2)
	text_lbl.add_theme_constant_override("line_spacing", 6)
	vbox.add_child(text_lbl)

	var prompt_lbl := Label.new()
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.text = "[ Press Space / Enter or Click to continue ]"
	if custom_font:
		prompt_lbl.add_theme_font_override("font", custom_font)
	prompt_lbl.add_theme_font_size_override("font_size", 20)
	prompt_lbl.add_theme_color_override("font_color", Color(0.62, 0.18, 0.20, 0.0))
	vbox.add_child(prompt_lbl)

	var fade_in := create_tween()
	fade_in.tween_property(root, "modulate:a", 1.0, 1.2)
	await fade_in.finished

	await get_tree().create_timer(1.2).timeout

	var prompt_fade := create_tween()
	prompt_fade.tween_property(prompt_lbl, "theme_override_colors/font_color:a", 0.9, 0.8)

	# Wait for player confirmation or auto-advance after reading time
	var elapsed := 0.0
	while elapsed < 14.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact"):
			break

	var fade_out := create_tween()
	fade_out.tween_property(root, "modulate:a", 0.0, 0.8)
	await fade_out.finished
	layer.queue_free()

func _setup_thought_hud() -> void:
	if not _hud_layer:
		return

	_note_clean_tex = _load_fresh_texture("res://Assets/nota_limpia.png")
	_note_blood_tex = _load_fresh_texture("res://Assets/nota_sangre.png")

	# Wide horizontal note banner matching the blue box in the user's screenshot
	var note_w := 920.0
	var note_h := 205.0
	_thought_panel = Control.new()
	_thought_panel.name = "InnerThoughtPanel"
	_thought_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_thought_panel.offset_left = -note_w * 0.5 - 20.0
	_thought_panel.offset_top = -note_h - 58.0
	_thought_panel.offset_right = note_w * 0.5 - 20.0
	_thought_panel.offset_bottom = -58.0
	_thought_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_panel.visible = false
	_thought_panel.modulate.a = 0.0
	_hud_layer.add_child(_thought_panel)

	# 1. Wall Note background (paper image)
	_thought_bg = TextureRect.new()
	_thought_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thought_bg.texture = _note_clean_tex
	_thought_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thought_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_thought_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_panel.add_child(_thought_bg)

	# 2. Inner Monologue background (dark translucent subtitle frame, distinct from paper notes)
	_inner_voice_box = PanelContainer.new()
	_inner_voice_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inner_voice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner_voice_box.visible = false
	var voice_style := StyleBoxFlat.new()
	voice_style.bg_color = Color(0.03, 0.03, 0.045, 0.78)
	voice_style.border_width_left = 3
	voice_style.border_width_right = 3
	voice_style.border_width_top = 1
	voice_style.border_width_bottom = 1
	voice_style.border_color = Color(0.55, 0.53, 0.48, 0.55)
	voice_style.corner_radius_top_left = 6
	voice_style.corner_radius_top_right = 6
	voice_style.corner_radius_bottom_left = 6
	voice_style.corner_radius_bottom_right = 6
	_inner_voice_box.add_theme_stylebox_override("panel", voice_style)
	_thought_panel.add_child(_inner_voice_box)

	_thought_margin = MarginContainer.new()
	_thought_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thought_margin.add_theme_constant_override("margin_left", 92)
	_thought_margin.add_theme_constant_override("margin_right", 92)
	_thought_margin.add_theme_constant_override("margin_top", 28)
	_thought_margin.add_theme_constant_override("margin_bottom", 26)
	_thought_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_panel.add_child(_thought_margin)

	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	_thought_body_label = Label.new()
	_thought_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thought_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thought_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if custom_font:
		_thought_body_label.add_theme_font_override("font", custom_font)
	_thought_body_label.add_theme_font_size_override("font_size", 23)
	_thought_body_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 0.96))
	_thought_body_label.add_theme_constant_override("line_spacing", 4)
	_thought_margin.add_child(_thought_body_label)

func _display_wall_note_text(body_text: String, bloody: bool = false, duration: float = 5.5) -> void:
	if not _thought_panel:
		return
	if _thought_bg:
		_thought_bg.visible = true
		_thought_bg.texture = _note_blood_tex if (bloody and _note_blood_tex) else _note_clean_tex
	if _inner_voice_box:
		_inner_voice_box.visible = false
	if _thought_margin:
		_thought_margin.add_theme_constant_override("margin_left", 92)
		_thought_margin.add_theme_constant_override("margin_right", 92)
		_thought_margin.add_theme_constant_override("margin_top", 28)
		_thought_margin.add_theme_constant_override("margin_bottom", 26)

	_thought_body_label.text = body_text
	_thought_body_label.add_theme_font_size_override("font_size", 23)
	_thought_body_label.add_theme_color_override("font_color", Color(0.16, 0.04, 0.04, 0.97) if bloody else Color(0.08, 0.08, 0.07, 0.96))
	_thought_body_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0))

	_animate_thought_panel(duration)

func _display_inner_thought(body_text: String, bloody: bool = false, duration: float = 4.2) -> void:
	if not _thought_panel:
		return
	if _thought_bg:
		_thought_bg.visible = false
	if _inner_voice_box:
		_inner_voice_box.visible = true
		var voice_style := _inner_voice_box.get_theme_stylebox("panel") as StyleBoxFlat
		if voice_style:
			voice_style.border_color = Color(0.68, 0.16, 0.18, 0.72) if bloody else Color(0.55, 0.53, 0.48, 0.55)
			voice_style.bg_color = Color(0.05, 0.015, 0.02, 0.82) if bloody else Color(0.025, 0.025, 0.038, 0.78)
	if _thought_margin:
		_thought_margin.add_theme_constant_override("margin_left", 44)
		_thought_margin.add_theme_constant_override("margin_right", 44)
		_thought_margin.add_theme_constant_override("margin_top", 22)
		_thought_margin.add_theme_constant_override("margin_bottom", 22)

	_thought_body_label.text = "“ " + body_text + " ”"
	_thought_body_label.add_theme_font_size_override("font_size", 22)
	_thought_body_label.add_theme_color_override("font_color", Color(0.95, 0.52, 0.52, 0.98) if bloody else Color(0.88, 0.86, 0.81, 0.96))
	_thought_body_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	_thought_body_label.add_theme_constant_override("shadow_offset_x", 2)
	_thought_body_label.add_theme_constant_override("shadow_offset_y", 2)

	_animate_thought_panel(duration)

func _animate_thought_panel(duration: float) -> void:
	_thought_panel.visible = true
	if _thought_tween and _thought_tween.is_valid():
		_thought_tween.kill()
	_thought_tween = create_tween()
	_thought_tween.tween_property(_thought_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	_thought_tween.tween_interval(duration)
	_thought_tween.tween_property(_thought_panel, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	_thought_tween.tween_callback(func():
		_thought_panel.visible = false
	)

func _setup_damage_indicator() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "PlayerDamageHUD"
	_hud_layer.layer = 10
	add_child(_hud_layer)

	_damage_border_drawer = _DamageBorderControl.new()
	_damage_border_drawer.name = "DamageBorderDarkness"
	_damage_border_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_border_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_damage_border_drawer)

	_damage_vignette_rect = TextureRect.new()
	_damage_vignette_rect.name = "DamageVignette"
	_damage_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_vignette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_damage_vignette_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_damage_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://Assets/sprites/damage_vignette.png"):
		_damage_vignette_rect.texture = load("res://Assets/sprites/damage_vignette.png")
	_damage_vignette_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_hud_layer.add_child(_damage_vignette_rect)

	_update_damage_indicator(0.0)

func _update_damage_indicator(delta: float) -> void:
	if not _damage_vignette_rect or not _damage_border_drawer:
		return

	var missing_ratio := 1.0 - clampf(float(maxi(life, 0)) / float(maxi(max_life, 1)), 0.0, 1.0)
	_damage_flash_intensity = move_toward(_damage_flash_intensity, 0.0, delta * 1.65)

	if missing_ratio <= 0.001 and _damage_flash_intensity <= 0.001:
		_damage_vignette_rect.modulate.a = 0.0
		if _damage_border_drawer.intensity > 0.0:
			_damage_border_drawer.intensity = 0.0
			_damage_border_drawer.queue_redraw()
		return

	# Heartbeat pulse speeds up when critically injured (1 HP left)
	var pulse_speed := 3.0 if missing_ratio < 0.5 else 6.2
	_injury_pulse_time += delta * pulse_speed
	var pulse := 0.5 + 0.5 * sin(_injury_pulse_time)

	var base_alpha := 0.0
	if missing_ratio >= 0.99:
		base_alpha = 0.98
	elif missing_ratio >= 0.5:
		# Critical injury (1/3 life): strong dark & bloodied periphery
		base_alpha = 0.78 + 0.18 * pulse
	elif missing_ratio > 0.0:
		# Moderate injury (2/3 life): noticeable darkened & hurt edges
		base_alpha = 0.46 + 0.14 * pulse

	var final_alpha := clampf(maxf(base_alpha, _damage_flash_intensity * 0.92), 0.0, 1.0)
	_damage_vignette_rect.modulate = Color(1.0, 1.0, 1.0, final_alpha)

	var border_darkness := clampf(missing_ratio * 0.85 + _damage_flash_intensity * 0.45 + pulse * 0.12 * missing_ratio, 0.0, 1.0)
	_damage_border_drawer.intensity = border_darkness
	_damage_border_drawer.queue_redraw()

func _show_intro_notes() -> void:
	if get_node_or_null("/root/GameManager"):
		if GameManager.get("current_phase") != null and GameManager.current_phase >= 2:
			if _watch_overlay and _watch_overlay.has_method("start_countdown"):
				_watch_overlay.start_countdown()
			return
		if GameManager.get("intro_notes_shown") == true:
			if _watch_overlay and _watch_overlay.has_method("start_countdown"):
				_watch_overlay.start_countdown()
			return

	is_reading_intro = true
	var prev_process_mode := process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var layer := CanvasLayer.new()
	layer.layer = 115
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.focus_mode = Control.FOCUS_ALL
	layer.add_child(root)
	root.grab_focus()

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.01, 0.015, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var note_w := 1144.0
	var note_h := 582.0
	var note_tex: Texture2D = _load_fresh_texture("res://Assets/nota_limpia.png")

	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	var note_holder := Control.new()
	note_holder.custom_minimum_size = Vector2(note_w, note_h)
	note_holder.pivot_offset = Vector2(note_w * 0.5, note_h * 0.5)
	note_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(note_holder)

	var note_bg := TextureRect.new()
	note_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_bg.texture = note_tex
	note_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_holder.add_child(note_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 140)
	margin.add_theme_constant_override("margin_right", 140)
	margin.add_theme_constant_override("margin_top", 84)
	margin.add_theme_constant_override("margin_bottom", 74)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_holder.add_child(margin)

	# --- NOTE 1: Title "Scape before time’s up." ---
	var note1_box := VBoxContainer.new()
	note1_box.alignment = BoxContainer.ALIGNMENT_CENTER
	note1_box.add_theme_constant_override("separation", 34)
	note1_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(note1_box)

	var title_lbl := Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.text = "Scape before time’s up."
	if custom_font:
		title_lbl.add_theme_font_override("font", custom_font)
	title_lbl.add_theme_font_size_override("font_size", 54)
	title_lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 0.96))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.62, 0.64, 0.56, 0.45))
	title_lbl.add_theme_constant_override("outline_size", 2)
	note1_box.add_child(title_lbl)

	var divider1 := ColorRect.new()
	divider1.custom_minimum_size = Vector2(480, 2)
	divider1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider1.color = Color(0.12, 0.12, 0.10, 0.55)
	divider1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note1_box.add_child(divider1)

	var sub1_lbl := Label.new()
	sub1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub1_lbl.text = "[ Press any key or Click to read the next note ]"
	if custom_font:
		sub1_lbl.add_theme_font_override("font", custom_font)
	sub1_lbl.add_theme_font_size_override("font_size", 22)
	sub1_lbl.add_theme_color_override("font_color", Color(0.14, 0.14, 0.12, 0.85))
	note1_box.add_child(sub1_lbl)

	# --- NOTE 2: Controls ---
	var note2_box := VBoxContainer.new()
	note2_box.visible = false
	note2_box.alignment = BoxContainer.ALIGNMENT_CENTER
	note2_box.add_theme_constant_override("separation", 16)
	note2_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(note2_box)

	var ctrl_header := Label.new()
	ctrl_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_header.text = "— CONTROLS —"
	if custom_font:
		ctrl_header.add_theme_font_override("font", custom_font)
	ctrl_header.add_theme_font_size_override("font_size", 36)
	ctrl_header.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 0.96))
	note2_box.add_child(ctrl_header)

	var divider2 := ColorRect.new()
	divider2.custom_minimum_size = Vector2(580, 2)
	divider2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider2.color = Color(0.12, 0.12, 0.10, 0.50)
	divider2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note2_box.add_child(divider2)

	var controls_grid := GridContainer.new()
	controls_grid.columns = 2
	controls_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_grid.add_theme_constant_override("h_separation", 38)
	controls_grid.add_theme_constant_override("v_separation", 12)
	controls_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note2_box.add_child(controls_grid)

	var rows := [
		["[ W A S D ]", "Move"],
		["[ R ]", "Check watch"],
		["[ Left Click ] / [ J ] / [ X ]", "Attack / Shoot"],
		["[ E ] / [ K ] / [ Z ]", "Interact / Read / Pick up"],
		["[ Arrows ] / [ 1 2 3 ] / [ Wheel ]", "Select weapon"]
	]
	for pair in rows:
		var k_lbl := Label.new()
		k_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k_lbl.text = pair[0]
		if custom_font:
			k_lbl.add_theme_font_override("font", custom_font)
		k_lbl.add_theme_font_size_override("font_size", 24)
		k_lbl.add_theme_color_override("font_color", Color(0.07, 0.07, 0.06, 0.96))
		controls_grid.add_child(k_lbl)

		var act_lbl := Label.new()
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		act_lbl.text = "—   " + pair[1]
		if custom_font:
			act_lbl.add_theme_font_override("font", custom_font)
		act_lbl.add_theme_font_size_override("font_size", 24)
		act_lbl.add_theme_color_override("font_color", Color(0.13, 0.13, 0.11, 0.92))
		controls_grid.add_child(act_lbl)

	var sub2_lbl := Label.new()
	sub2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2_lbl.text = "[ Press any key or Click to begin ]"
	if custom_font:
		sub2_lbl.add_theme_font_override("font", custom_font)
	sub2_lbl.add_theme_font_size_override("font_size", 22)
	sub2_lbl.add_theme_color_override("font_color", Color(0.14, 0.14, 0.12, 0.85))
	note2_box.add_child(sub2_lbl)

	root.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_intro_note_advance_requested = true
	)

	note_holder.modulate.a = 0.0
	note_holder.scale = Vector2(0.94, 0.94)
	var t_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	t_in.tween_property(note_holder, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_SINE)
	t_in.tween_property(note_holder, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t_in.finished

	await _wait_for_note_advance()

	var t_flip_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	t_flip_out.tween_property(note_holder, "modulate:a", 0.0, 0.15)
	t_flip_out.tween_property(note_holder, "scale", Vector2(0.96, 0.96), 0.15)
	await t_flip_out.finished

	note1_box.visible = false
	note2_box.visible = true

	var t_flip_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	t_flip_in.tween_property(note_holder, "modulate:a", 1.0, 0.20)
	t_flip_in.tween_property(note_holder, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t_flip_in.finished

	await _wait_for_note_advance()

	var t_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t_out.tween_property(root, "modulate:a", 0.0, 0.22)
	await t_out.finished

	layer.queue_free()
	get_tree().paused = false
	process_mode = prev_process_mode
	is_reading_intro = false
	if get_node_or_null("/root/GameManager"):
		GameManager.intro_notes_shown = true

	# Start the 4-minute countdown now that the player can move
	if _watch_overlay and _watch_overlay.has_method("start_countdown"):
		_watch_overlay.start_countdown()

func _wait_for_note_advance() -> void:
	var release_guard := 0
	while Input.is_anything_pressed() and release_guard < 30:
		await get_tree().process_frame
		release_guard += 1
	await get_tree().process_frame
	_intro_note_advance_requested = false

	while not _intro_note_advance_requested:
		await get_tree().process_frame
		if Input.is_anything_pressed() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_intro_note_advance_requested = true
			break

func _input(event: InputEvent) -> void:
	if not is_reading_intro:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_intro_note_advance_requested = true
	elif event is InputEventMouseButton and event.pressed:
		_intro_note_advance_requested = true
	elif event is InputEventJoypadButton and event.pressed:
		_intro_note_advance_requested = true

func _setup_labyrinth_props_and_void() -> void:
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

	var parent_map := get_parent()
	if not parent_map:
		return

	var gatillo := parent_map.get_node_or_null("GatilloDialogo")
	if gatillo:
		gatillo.queue_free()
	if get_node_or_null("/root/DialogSystem") and DialogSystem.get("caja"):
		DialogSystem.caja.hide()

	if not parent_map.get_node_or_null("VoidBlackBackground"):
		var bg_layer := CanvasLayer.new()
		bg_layer.name = "VoidBlackBackground"
		bg_layer.layer = -100
		var black_rect := ColorRect.new()
		black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		black_rect.color = Color(0, 0, 0, 1)
		black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_layer.add_child(black_rect)
		parent_map.add_child.call_deferred(bg_layer)

	if parent_map.get_node_or_null("floor_layer") and not parent_map.get_node_or_null("LabyrinthPropsSpawner"):
		var spawner := Node2D.new()
		spawner.name = "LabyrinthPropsSpawner"
		spawner.y_sort_enabled = true
		spawner.set_script(LabyrinthPropsSpawnerScript)
		parent_map.add_child.call_deferred(spawner)

func _setup_watch_overlay() -> void:
	_watch_overlay = CanvasLayer.new()
	_watch_overlay.set_script(WatchOverlayScript)
	_watch_overlay.character = self
	add_child(_watch_overlay)


class _DamageBorderControl extends Control:
	var intensity: float = 0.0

	func _draw() -> void:
		if intensity <= 0.001 or size.x <= 0.0 or size.y <= 0.0:
			return
		var rings := 18
		var max_inset_x := size.x * (0.18 + 0.14 * intensity)
		var max_inset_y := size.y * (0.18 + 0.14 * intensity)
		for i in range(rings):
			var t := float(i) / float(rings)
			var next_t := float(i + 1) / float(rings)
			var ix0 := max_inset_x * t
			var iy0 := max_inset_y * t
			var ix1 := max_inset_x * next_t
			var iy1 := max_inset_y * next_t
			var falloff := pow(1.0 - t, 1.8)
			var a := clampf(intensity * 0.16 * falloff, 0.0, 0.85)
			var col := Color(0.05 * (1.0 - t), 0.005, 0.008, a)
			# Top strip
			draw_rect(Rect2(ix0, iy0, size.x - 2.0 * ix0, iy1 - iy0 + 1.0), col)
			# Bottom strip
			draw_rect(Rect2(ix0, size.y - iy1, size.x - 2.0 * ix0, iy1 - iy0 + 1.0), col)
			# Left strip
			draw_rect(Rect2(ix0, iy1, ix1 - ix0 + 1.0, size.y - 2.0 * iy1), col)
			# Right strip
			draw_rect(Rect2(size.x - ix1, iy1, ix1 - ix0 + 1.0, size.y - 2.0 * iy1), col)


func _on_animated_sprite_2d_frame_changed() -> void:
	# Footsteps are now handled smoothly by _footstep_timer with natural shoe step sounds
	pass


class _PistolBullet extends Area2D:
	var direction: Vector2 = Vector2.UP
	var speed: float = 2100.0
	var damage: int = 35
	var shooter: Node2D = null
	var _lifetime: float = 2.0
	var _hit: bool = false

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 4 | 8 # Enemies/Boss (layer 3 -> bit 4) + Walls (layer 4 -> bit 8)
		monitoring = true
		monitorable = true

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 16.0
		col.shape = shape
		add_child(col)

		# Bullet tracer visual
		var tracer := Polygon2D.new()
		tracer.polygon = PackedVector2Array([
			Vector2(-26, -4), Vector2(18, -5), Vector2(26, 0), Vector2(18, 5), Vector2(-26, 4)
		])
		tracer.color = Color(1.0, 0.90, 0.45, 0.98)
		tracer.rotation = direction.angle()
		z_index = 25
		add_child(tracer)

		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)

	func _physics_process(delta: float) -> void:
		if _hit:
			return
		global_position += direction * speed * delta
		_lifetime -= delta
		if _lifetime <= 0.0:
			queue_free()

	func _on_body_entered(body: Node2D) -> void:
		if _hit or not body or body == shooter:
			return
		if body.is_in_group("player"):
			return
		if body.is_in_group("boss") or body.is_in_group("enemy") or body.has_method("take_damage"):
			_hit = true
			if body.has_method("take_damage"):
				body.take_damage(damage)
			queue_free()
		elif body is TileMapLayer or body is StaticBody2D:
			_hit = true
			queue_free()

	func _on_area_entered(area: Area2D) -> void:
		if _hit or not area:
			return
		var p := area.get_parent()
		if p and p != shooter and (p.is_in_group("boss") or p.is_in_group("enemy") or p.has_method("take_damage")):
			_hit = true
			if p.has_method("take_damage"):
				p.take_damage(damage)
			queue_free()
