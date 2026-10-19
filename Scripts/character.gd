class_name Character
extends CharacterBody2D

const WatchOverlayScript = preload("res://Scripts/watch_overlay.gd")
const LabyrinthPropsSpawnerScript = preload("res://Scripts/labyrinth_props_spawner.gd")

const FLASHBACK_TEXT := """All my life, I’ve heard that souls are not born evil, but are corrupted over time. I thought this was true, although I never stopped asking myself: Can souls really not be born from darkness? What’s the thing that can break your spirit to the point of staining your soul?

Fame, greatness, I never wanted any of that. I didn’t even want to stand out. There was only one thing in this world that mattered to me: to serve, protect, and to care for others. I had seen what violence did to people, and I didn’t want it to do it to me.

But being a cop is inherently violent in a way, isn’t it? Does that mean that violence is inherently a part of me?"""

const PACIFIST_MORALITY_THOUGHTS: Array[String] = [
	"Hold on... I'm a police officer, not an executioner. Guide me around it—we don't need to use lethal force.",
	"Look at how slow it moves... It's not a threat if we keep our distance. Please, help me uphold my oath.",
	"I swore to serve and protect... Don't make me swing this weapon unless we have no other choice.",
	"My hand is trembling over my badge... Just lead me past it, okay? Let's keep our hands clean.",
	"We don't have to beat every shadow in our path... Keep me moving forward, please.",
	"Every blow leaves a stain a badge can't cover... Let's just slip past it."
]

const KILL_THOUGHTS_STAGE_1: Array[String] = [
	"Wait... is that another suspect ahead? You want me to use force again, don't you?",
	"There's blood on my uniform now... Tell me we're only doing what cops have to do to survive.",
	"Why are you steering me straight toward it? Are we keeping the peace... or looking for an excuse to strike?"
]

const KILL_THOUGHTS_STAGE_2: Array[String] = [
	"Another threat in our jurisdiction... Go on, make me swing. Put them down before they even flinch!",
	"To serve and protect... No, down here the law is whatever weapon we're holding, isn't it?",
	"Look at it staring at my badge... It's guilty. They're all guilty! Tell me to strike!"
]

const KILL_THOUGHTS_STAGE_3: Array[String] = [
	"DON'T LET IT BREATHE! Move me closer—let's show this shadow what police force really means!",
	"There's no innocence down here! You want blood, I'll give you blood—just press the button, partner!",
	"My head is spinning, hahaha... No more rules, no more reports! Just you, me, and the next target!"
]

const WALL_NOTE_INSANITY_STAGE_1: Array[String] = [
	"My badge is stained... You saw it, right? It was self-defense. Keep guiding me—tell me I'm still a good cop.",
	"My pulse won't slow down... On the force, they said the first strike is the hardest. Why are you making it feel so easy?"
]

const WALL_NOTE_INSANITY_STAGE_2: Array[String] = [
	"The blood won't come off my uniform... Are you doing this to my mind, or was this brutality always hiding behind my badge?",
	"I can hear police sirens screaming in my head... Don't stop now, partner. Help me clear every last corridor."
]

const WALL_NOTE_INSANITY_STAGE_3: Array[String] = [
	"Sanity? Law? Who needs an oath when we hold authority over life and death! Keep pushing me forward, partner—let's finish this patrol in blood!",
	"Look at my hands—soaked in red and steady as stone! You and I are the judge, the jury, and the trigger down here!"
]

@export var speed = 450
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

# Organic inner thought / sanity wall note HUD (no titles)
var _thought_panel: PanelContainer = null
var _thought_body_label: Label = null
var _thought_tween: Tween = null
var _morality_thought_index: int = 0
var _wall_insanity_index: int = 0
var _global_morality_cooldown: float = 0.0
var _triggered_by_flashback_note: bool = false

@onready var point_equipment: Marker2D = $EquipmentPoint
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	life = max_life
	add_to_group("player")
	_setup_labyrinth_props_and_void()
	_setup_watch_overlay()
	_setup_damage_indicator()
	_setup_thought_hud()
	call_deferred("_show_intro_notes")

func _process(delta: float) -> void:
	_update_damage_indicator(delta)
	if _global_morality_cooldown > 0.0:
		_global_morality_cooldown = maxf(0.0, _global_morality_cooldown - delta)

func _physics_process(delta: float) -> void:
	if is_reading_intro:
		return

	var attack = Input.is_action_just_pressed("attack")
	
	if attack and weapon_equiped and not is_dead:
		attacking(weapon_equiped.weapon_name)

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
	else:
		play_animation(last_direction, "Idle")
	move_and_slide()

func play_animation(direction: Vector2, prefix: String):
	if direction.x != 0:
		animated_sprite_2d.flip_h = direction.x < 0
		animated_sprite_2d.play(prefix + "_Side")
	elif direction.y < 0:
		animated_sprite_2d.play(prefix + "_Back")
	elif direction.y > 0:
		animated_sprite_2d.play(prefix + "_Front")

func attacking(suffix: String) -> void:
	is_attacking = true
	if point_equipment:
		point_equipment.rotation = last_direction.angle() - PI / 2
	weapon_equiped.enable_hitbox()
	animated_sprite_2d.play("Attack_" + suffix)
	await animated_sprite_2d.animation_finished
	is_attacking = false
	if weapon_equiped:
		weapon_equiped.disable_hitbox()

func equip_weapon(new_weapon: PackedScene):
	if weapon_equiped:
		weapon_equiped.queue_free()
		
	weapon_equiped = new_weapon.instantiate() as ArmaBase
	if weapon_equiped:
		point_equipment.add_child(weapon_equiped)
		weapon_equiped.position = Vector2.ZERO
		weapon_equiped.rotation = 0

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

	if total == 1:
		_display_inner_thought("I killed it... Why did you make me strike? It was self-defense, right? Tell me that was lawful force...", Color(0.92, 0.78, 0.74, 0.98), 4.8)
	elif total == 2:
		_display_inner_thought("Another one down... My hands are shaking, or maybe they're finally steady. You saw it resisting too, didn't you?", Color(0.93, 0.68, 0.64, 0.98), 4.8)
	elif total == 3:
		_display_inner_thought("Three down... Look at them fall. We wear the badge in this place—we decide who's guilty, don't we?", Color(0.94, 0.56, 0.52, 0.98), 4.8)
	elif total == 4:
		_display_inner_thought("Stop resisting! ...Wait, it wasn't even fighting back. Why am I smiling? Why aren't you stopping me?!", Color(0.95, 0.44, 0.42, 0.98), 5.0)
	else:
		_display_inner_thought("CLEAN THE STREETS! PUT THEM ALL DOWN! ...Look at us, partner—the badge looks so much better soaked in red!", Color(0.96, 0.34, 0.34, 0.98), 5.0)

func trigger_enemy_morality_thought() -> void:
	if is_dead or is_reading_intro or _global_morality_cooldown > 0.0:
		return
	_global_morality_cooldown = 6.5

	var total := _get_total_kills()
	var line := ""
	var text_col := Color(0.92, 0.90, 0.85, 0.98)

	if total <= 0:
		line = PACIFIST_MORALITY_THOUGHTS[_morality_thought_index % PACIFIST_MORALITY_THOUGHTS.size()]
	elif total <= 2:
		line = KILL_THOUGHTS_STAGE_1[_morality_thought_index % KILL_THOUGHTS_STAGE_1.size()]
		text_col = Color(0.92, 0.78, 0.74, 0.98)
	elif total <= 4:
		line = KILL_THOUGHTS_STAGE_2[_morality_thought_index % KILL_THOUGHTS_STAGE_2.size()]
		text_col = Color(0.94, 0.56, 0.52, 0.98)
	else:
		line = KILL_THOUGHTS_STAGE_3[_morality_thought_index % KILL_THOUGHTS_STAGE_3.size()]
		text_col = Color(0.96, 0.36, 0.36, 0.98)

	_morality_thought_index += 1
	_display_inner_thought(line, text_col, 4.4)

func show_sanity_wall_note_thought(base_text: String) -> void:
	if is_dead:
		return
	_global_morality_cooldown = 5.0
	var total := _get_total_kills()
	var final_text := base_text
	var text_col := Color(0.94, 0.92, 0.86, 0.98)

	if total >= 5:
		final_text = WALL_NOTE_INSANITY_STAGE_3[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_3.size()]
		text_col = Color(0.96, 0.38, 0.38, 0.98)
		_wall_insanity_index += 1
	elif total >= 3:
		final_text = WALL_NOTE_INSANITY_STAGE_2[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_2.size()]
		text_col = Color(0.94, 0.58, 0.54, 0.98)
		_wall_insanity_index += 1
	elif total >= 1:
		final_text = WALL_NOTE_INSANITY_STAGE_1[_wall_insanity_index % WALL_NOTE_INSANITY_STAGE_1.size()]
		text_col = Color(0.92, 0.78, 0.74, 0.98)
		_wall_insanity_index += 1

	_display_inner_thought(final_text, text_col, 5.6)

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
	if spawner and spawner.has_method("clear_phase_one_wall_notes"):
		spawner.clear_phase_one_wall_notes()

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
	velocity = Vector2.ZERO

	if _watch_overlay and _watch_overlay.has_method("force_close"):
		_watch_overlay.force_close()

	if weapon_equiped and weapon_equiped.has_method("disable_hitbox"):
		weapon_equiped.disable_hitbox()

	animated_sprite_2d.play("Die")
	await animated_sprite_2d.animation_finished

	await get_tree().create_timer(0.35).timeout
	await _show_enemy_death_note()

	if get_node_or_null("/root/GameManager") and GameManager.has_method("reset_kills"):
		GameManager.reset_kills()
	get_tree().reload_current_scene()

func _show_enemy_death_note() -> void:
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

	var note_tex: Texture2D = null
	if ResourceLoader.exists("res://Assets/nota_sangre.png"):
		note_tex = load("res://Assets/nota_sangre.png")
	elif ResourceLoader.exists("res://Assets/nota_limpia.png"):
		note_tex = load("res://Assets/nota_limpia.png")

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

	animated_sprite_2d.modulate = Color.WHITE
	animated_sprite_2d.play("Die")
	await animated_sprite_2d.animation_finished

	await get_tree().create_timer(0.6).timeout

	# Whether the player dealt damage to any enemy in the first phase or not,
	# show the flashback monologue with the Special Elite font when time runs out.
	await _show_timeout_flashback()
	if _triggered_by_flashback_note and get_node_or_null("/root/GameManager") and GameManager.has_method("advance_to_phase_two"):
		GameManager.advance_to_phase_two()
	get_tree().reload_current_scene()

func _show_timeout_flashback() -> void:
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
	text_lbl.text = FLASHBACK_TEXT
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

	_thought_panel = PanelContainer.new()
	_thought_panel.name = "InnerThoughtPanel"
	_thought_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_thought_panel.offset_left = -460.0
	_thought_panel.offset_top = -140.0
	_thought_panel.offset_right = 460.0
	_thought_panel.offset_bottom = -36.0
	_thought_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_panel.visible = false
	_thought_panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.026, 0.86)
	style.border_color = Color(0.24, 0.23, 0.20, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.82)
	style.shadow_size = 10
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	_thought_panel.add_theme_stylebox_override("panel", style)
	_hud_layer.add_child(_thought_panel)

	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	_thought_body_label = Label.new()
	_thought_body_label.custom_minimum_size = Vector2(860.0, 0.0)
	_thought_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thought_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if custom_font:
		_thought_body_label.add_theme_font_override("font", custom_font)
	_thought_body_label.add_theme_font_size_override("font_size", 24)
	_thought_body_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85, 0.98))
	_thought_body_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_thought_body_label.add_theme_constant_override("outline_size", 5)
	_thought_panel.add_child(_thought_body_label)

func _display_inner_thought(body_text: String, text_col: Color = Color(0.92, 0.90, 0.85, 0.98), duration: float = 4.2) -> void:
	if not _thought_panel:
		return
	_thought_body_label.text = body_text
	_thought_body_label.add_theme_color_override("font_color", text_col)

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
	var note_tex: Texture2D = null
	if ResourceLoader.exists("res://Assets/nota_limpia.png"):
		note_tex = load("res://Assets/nota_limpia.png")

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
		["[ W A S D ]  /  [ Arrows ]", "Move"],
		["[ R ]", "Check watch"],
		["[ Left Click ]  /  [ J ]", "Strike / Attack"],
		["[ E ]", "Pick up objects"]
	]
	for pair in rows:
		var k_lbl := Label.new()
		k_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k_lbl.text = pair[0]
		if custom_font:
			k_lbl.add_theme_font_override("font", custom_font)
		k_lbl.add_theme_font_size_override("font_size", 27)
		k_lbl.add_theme_color_override("font_color", Color(0.07, 0.07, 0.06, 0.96))
		controls_grid.add_child(k_lbl)

		var act_lbl := Label.new()
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		act_lbl.text = "—   " + pair[1]
		if custom_font:
			act_lbl.add_theme_font_override("font", custom_font)
		act_lbl.add_theme_font_size_override("font_size", 27)
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
