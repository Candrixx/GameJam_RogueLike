class_name WatchOverlay
extends CanvasLayer

const WATCH_TEXTURE_PATH := "res://Assets/reloj/Mano policia.png"
const CUSTOM_FONT_PATH := "res://Assets/fonts/SpecialElite-Regular.ttf"
const INITIAL_TIME := 240.0 # 4 minutes in seconds

var is_open: bool = false
var countdown_started: bool = false
var is_rapid_draining: bool = false
var _rapid_drain_speed: float = 160.0
var time_left: float = INITIAL_TIME
var elapsed_watch_time: float = 0.0
var _timeout_triggered: bool = false
var character: Node = null
var _custom_font: Font = null

var _root_control: Control
var _dark_bg: ColorRect
var _hand_tex_rect: TextureRect
var _dial_drawer: Control
var _timer_panel: PanelContainer
var _title_label: Label
var _timer_label: Label
var _sub_label: Label
var _fade_tween: Tween = null

# Mini warning banner HUD (visible even when watch overlay is closed)
var _warning_panel: PanelContainer
var _warning_label: Label
var _warning_sub_label: Label
var _warning_tween: Tween = null
var _watch_hint_label: Label = null
var _warned_180: bool = false
var _warned_120: bool = false
var _warned_60: bool = false
var _warned_30: bool = false

# Watch sound effects
var _tick_player: AudioStreamPlayer
var _chime_player: AudioStreamPlayer
var _sfx_tick: AudioStreamWAV
var _sfx_tock: AudioStreamWAV
var _sfx_chime: AudioStreamWAV
var _sfx_urgent_chime: AudioStreamWAV
var _tick_accumulator: float = 0.0
var _is_tock: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(CUSTOM_FONT_PATH):
		_custom_font = load(CUSTOM_FONT_PATH)
	_setup_watch_audio()
	_build_ui()
	_build_warning_banner()
	_build_watch_hint()
	_root_control.visible = false
	_root_control.modulate.a = 0.0

func start_countdown() -> void:
	countdown_started = true
	if _watch_hint_label:
		_watch_hint_label.visible = not is_open

func trigger_rapid_drain_to_zero() -> void:
	if _timeout_triggered:
		return
	countdown_started = true
	is_rapid_draining = true
	# Drain whatever time remains to 0 in ~1.8 seconds (minimum 90s/sec)
	_rapid_drain_speed = maxf(time_left / 1.75, 95.0)
	if _title_label:
		_title_label.text = "Time is collapsing..."
		_title_label.add_theme_color_override("font_color", Color(0.88, 0.22, 0.22, 0.98))
	if not is_open:
		toggle_watch()
	_play_chime(true)
	_show_time_warning("TIME IS COLLAPSING!", "00:00 Approaches...", true)

func _setup_watch_audio() -> void:
	var echo_bus := &"Master"
	if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
		echo_bus = GameManager.ensure_labyrinth_echo_bus()

	_tick_player = AudioStreamPlayer.new()
	_tick_player.volume_db = -6.0
	_tick_player.bus = echo_bus
	add_child(_tick_player)

	_chime_player = AudioStreamPlayer.new()
	_chime_player.volume_db = -4.0
	_chime_player.bus = echo_bus
	add_child(_chime_player)

	_sfx_tick = _generate_watch_tick_wav(2550.0, 0.032, 0.55)
	_sfx_tock = _generate_watch_tick_wav(1850.0, 0.036, 0.48)
	_sfx_chime = _generate_watch_chime_wav(740.0, 1110.0, 0.42, 0.42)
	_sfx_urgent_chime = _generate_watch_chime_wav(880.0, 1320.0, 0.55, 0.55)

func _generate_watch_tick_wav(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var samples := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(mix_rate)
		var env := exp(-t * 115.0)
		# Crisp mechanical escapement click + metallic ring
		var click := sin(TAU * freq * t) * 0.65 + sin(TAU * (freq * 1.92) * t) * 0.35
		if i < 28:
			click += (1.0 if i % 2 == 0 else -1.0) * 0.45
		var val := clampf(click * env * amp, -1.0, 1.0)
		var pcm := int(val * 32767.0)
		data.encode_s16(i * 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_watch_chime_wav(f1: float, f2: float, duration: float, amp: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var samples := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(mix_rate)
		var env := exp(-t * 7.2) * minf(t * 120.0, 1.0)
		var wave := sin(TAU * f1 * t) * 0.6 + sin(TAU * f2 * t) * 0.3 + sin(TAU * (f1 * 0.5) * t) * 0.2
		var val := clampf(wave * env * amp, -1.0, 1.0)
		var pcm := int(val * 32767.0)
		data.encode_s16(i * 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _play_tick(loud: bool = false) -> void:
	if not _tick_player:
		return
	_tick_player.volume_db = -3.5 if loud else -7.5
	_tick_player.stream = _sfx_tock if _is_tock else _sfx_tick
	_is_tock = not _is_tock
	_tick_player.play()

func _play_chime(urgent: bool = false) -> void:
	if not _chime_player:
		return
	_chime_player.volume_db = -2.5 if urgent else -5.0
	_chime_player.stream = _sfx_urgent_chime if urgent else _sfx_chime
	_chime_player.play()

func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.name = "WatchRoot"
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_control)

	# 1. Dark somber background
	_dark_bg = ColorRect.new()
	_dark_bg.name = "DarkBackground"
	_dark_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark_bg.color = Color(0.015, 0.015, 0.02, 0.92)
	_dark_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_dark_bg)

	# 2. "Mano policia" illustration
	_hand_tex_rect = TextureRect.new()
	_hand_tex_rect.name = "ManoPolicia"
	_hand_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hand_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hand_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(WATCH_TEXTURE_PATH):
		_hand_tex_rect.texture = load(WATCH_TEXTURE_PATH)
	_root_control.add_child(_hand_tex_rect)

	# 3. Animated watch hands & dial drawer
	_dial_drawer = _WatchDialControl.new()
	_dial_drawer.name = "WatchDialDrawer"
	_dial_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dial_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_drawer.overlay = self
	_root_control.add_child(_dial_drawer)

	# 4. 4-minute countdown panel with somber aesthetic
	_timer_panel = PanelContainer.new()
	_timer_panel.name = "CountdownPanel"
	_timer_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_panel.offset_left = -220.0
	_timer_panel.offset_top = 24.0
	_timer_panel.offset_right = 220.0
	_timer_panel.offset_bottom = 140.0
	_timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.04, 0.95)
	style.border_color = Color(0.24, 0.23, 0.20, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	style.shadow_size = 10
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_timer_panel.add_theme_stylebox_override("panel", style)
	_root_control.add_child(_timer_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	_timer_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Hurry, find the exit"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		_title_label.add_theme_font_override("font", _custom_font)
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.66, 0.63, 0.58, 0.92))
	_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_title_label.add_theme_constant_override("outline_size", 5)
	vbox.add_child(_title_label)

	_timer_label = Label.new()
	_timer_label.text = "04:00.00"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		_timer_label.add_theme_font_override("font", _custom_font)
	_timer_label.add_theme_font_size_override("font_size", 44)
	_timer_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.70, 0.95))
	_timer_label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.02, 1.0))
	_timer_label.add_theme_constant_override("outline_size", 7)
	vbox.add_child(_timer_label)

	_sub_label = Label.new()
	_sub_label.text = "[R] Hide watch"
	_sub_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub_label.offset_left = -200.0
	_sub_label.offset_top = -48.0
	_sub_label.offset_right = 200.0
	_sub_label.offset_bottom = -18.0
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		_sub_label.add_theme_font_override("font", _custom_font)
	_sub_label.add_theme_font_size_override("font_size", 16)
	_sub_label.add_theme_color_override("font_color", Color(0.55, 0.53, 0.49, 0.78))
	_sub_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_sub_label.add_theme_constant_override("outline_size", 4)
	_root_control.add_child(_sub_label)

func _build_warning_banner() -> void:
	_warning_panel = PanelContainer.new()
	_warning_panel.name = "TimeWarningBanner"
	_warning_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_warning_panel.offset_left = -310.0
	_warning_panel.offset_top = 22.0
	_warning_panel.offset_right = 310.0
	_warning_panel.offset_bottom = 108.0
	_warning_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_panel.visible = false
	_warning_panel.modulate.a = 0.0

	var w_style := StyleBoxFlat.new()
	w_style.bg_color = Color(0.03, 0.03, 0.038, 0.92)
	w_style.border_color = Color(0.55, 0.16, 0.16, 0.88)
	w_style.set_border_width_all(2)
	w_style.set_corner_radius_all(3)
	w_style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	w_style.shadow_size = 8
	w_style.content_margin_left = 22.0
	w_style.content_margin_right = 22.0
	w_style.content_margin_top = 10.0
	w_style.content_margin_bottom = 10.0
	_warning_panel.add_theme_stylebox_override("panel", w_style)
	add_child(_warning_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_panel.add_child(vbox)

	_warning_label = Label.new()
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		_warning_label.add_theme_font_override("font", _custom_font)
	_warning_label.add_theme_font_size_override("font_size", 24)
	_warning_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.78, 0.98))
	_warning_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_warning_label.add_theme_constant_override("outline_size", 6)
	vbox.add_child(_warning_label)

	_warning_sub_label = Label.new()
	_warning_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		_warning_sub_label.add_theme_font_override("font", _custom_font)
	_warning_sub_label.add_theme_font_size_override("font_size", 16)
	_warning_sub_label.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58, 0.90))
	vbox.add_child(_warning_sub_label)

func _build_watch_hint() -> void:
	_watch_hint_label = Label.new()
	_watch_hint_label.name = "WatchKeyHintLabel"
	_watch_hint_label.text = "[R] Check watch"
	_watch_hint_label.position = Vector2(28.0, 22.0)
	_watch_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_watch_hint_label.visible = false
	if _custom_font:
		_watch_hint_label.add_theme_font_override("font", _custom_font)
	_watch_hint_label.add_theme_font_size_override("font_size", 22)
	_watch_hint_label.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78, 0.90))
	_watch_hint_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_watch_hint_label.add_theme_constant_override("outline_size", 6)
	_watch_hint_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	_watch_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	_watch_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_watch_hint_label)

func _show_time_warning(main_text: String, sub_text: String, is_urgent: bool = false) -> void:
	if not _warning_panel:
		return
	_warning_label.text = main_text
	_warning_sub_label.text = sub_text
	if is_urgent:
		_warning_label.add_theme_color_override("font_color", Color(0.92, 0.24, 0.24, 0.98))
		_warning_sub_label.add_theme_color_override("font_color", Color(0.82, 0.55, 0.50, 0.95))
	else:
		_warning_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.76, 0.98))
		_warning_sub_label.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58, 0.90))

	_warning_panel.visible = true
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()
	_warning_tween = create_tween()
	_warning_tween.tween_property(_warning_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	if not is_urgent and time_left > 30.0:
		_warning_tween.tween_interval(3.4)
		_warning_tween.tween_property(_warning_panel, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
		_warning_tween.tween_callback(func():
			if time_left > 30.0:
				_warning_panel.visible = false
		)

func _input(event: InputEvent) -> void:
	if _timeout_triggered or is_rapid_draining:
		return
	if character and (character.get("is_dead") or character.get("is_reading_intro")):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R or event.physical_keycode == KEY_R:
			toggle_watch()

func toggle_watch() -> void:
	if _timeout_triggered:
		return
	is_open = not is_open
	_play_tick(true)
	if _watch_hint_label:
		_watch_hint_label.visible = countdown_started and not is_open

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	if is_open:
		_root_control.visible = true
		_update_timer_label()
		_dial_drawer.queue_redraw()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_root_control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
	else:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_root_control, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
		_fade_tween.tween_callback(func():
			if not is_open:
				_root_control.visible = false
		)

func force_close() -> void:
	is_open = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if _root_control:
		_root_control.modulate.a = 0.0
		_root_control.visible = false
	if _warning_panel:
		_warning_panel.visible = false
	if _watch_hint_label:
		_watch_hint_label.visible = false

func _process(delta: float) -> void:
	if character and (character.get("is_reading_intro") or character.get("is_dead")):
		return
	if countdown_started and not _timeout_triggered:
		var dt := delta
		if is_rapid_draining:
			elapsed_watch_time += delta * 28.0
			dt = delta * _rapid_drain_speed
		else:
			elapsed_watch_time += delta

		if time_left > 0.0:
			time_left = maxf(time_left - dt, 0.0)
			_check_milestone_warnings()
			_update_watch_ticking_audio(delta)

			if time_left <= 0.0:
				time_left = 0.0
				_timeout_triggered = true
				is_rapid_draining = false
				force_close()
				if character and character.has_method("die_from_timeout"):
					character.die_from_timeout()

	if _root_control.visible:
		_update_timer_label()
		_dial_drawer.queue_redraw()

func _check_milestone_warnings() -> void:
	if is_rapid_draining:
		return
	if not _warned_180 and time_left <= 180.0 and time_left > 175.0:
		_warned_180 = true
		_play_chime(false)
		_show_time_warning("3 MINUTES REMAINING", "Keep moving through the labyrinth...", false)
	elif not _warned_120 and time_left <= 120.0 and time_left > 115.0:
		_warned_120 = true
		_play_chime(false)
		_show_time_warning("2 MINUTES REMAINING", "The darkness is closing in...", false)
	elif not _warned_60 and time_left <= 60.0 and time_left > 55.0:
		_warned_60 = true
		_play_chime(true)
		_show_time_warning("1 MINUTE LEFT!", "Hurry, find a way out!", true)
	elif not _warned_30 and time_left <= 30.0:
		_warned_30 = true
		_play_chime(true)
		_show_time_warning("30 SECONDS LEFT!", "Time is almost up!", true)

	# Keep live tense countdown updated in the top mini-banner during the last 30 seconds (when watch overlay is closed)
	if time_left <= 30.0 and time_left > 0.0:
		if _warning_panel:
			_warning_panel.visible = not is_open
			if not is_open:
				_warning_panel.modulate.a = 0.96
				var secs := int(ceil(time_left))
				var pulse := 0.5 + 0.5 * sin(elapsed_watch_time * 9.0)
				_warning_label.text = "⚠ %02d SECONDS LEFT!" % secs
				_warning_label.add_theme_color_override("font_color", Color(0.78 + 0.20 * pulse, 0.16, 0.16, 0.98))
				_warning_sub_label.text = "Hurry, find the exit before time runs out!"

func _update_watch_ticking_audio(delta: float) -> void:
	var should_tick := is_open or is_rapid_draining or (time_left <= 30.0 and time_left > 0.0)
	if not should_tick:
		_tick_accumulator = 0.0
		return

	var interval := 1.0
	if is_rapid_draining:
		interval = 0.065
	elif time_left <= 10.0:
		interval = 0.25
	elif time_left <= 30.0:
		interval = 0.5

	_tick_accumulator += delta
	if _tick_accumulator >= interval:
		_tick_accumulator = fmod(_tick_accumulator, interval)
		_play_tick(is_open or is_rapid_draining or time_left <= 15.0)

func _update_timer_label() -> void:
	var total_sec := int(floor(time_left))
	var mins := total_sec / 60
	var secs := total_sec % 60
	var centis := int(floor((time_left - floor(time_left)) * 100.0))
	_timer_label.text = "%02d:%02d.%02d" % [mins, secs, centis]

	if time_left <= 10.0 or is_rapid_draining:
		var pulse := 0.5 + 0.5 * sin(elapsed_watch_time * 10.0)
		_timer_label.add_theme_color_override("font_color", Color(0.72 + 0.22 * pulse, 0.14, 0.14, 0.98))
	elif time_left <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(0.82, 0.36, 0.24, 0.95))
	else:
		_timer_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.70, 0.95))


class _WatchDialControl extends Control:
	var overlay: WatchOverlay

	func _draw() -> void:
		if not overlay:
			return

		var tex_aspect := 1920.0 / 1080.0
		var rect_w := size.x
		var rect_h := size.y
		if rect_h <= 0.0 or rect_w <= 0.0:
			return

		var draw_w := rect_w
		var draw_h := rect_h
		var offset_x := 0.0
		var offset_y := 0.0

		if rect_w / rect_h > tex_aspect:
			draw_w = rect_h * tex_aspect
			offset_x = (rect_w - draw_w) * 0.5
		else:
			draw_h = rect_w / tex_aspect
			offset_y = (rect_h - draw_h) * 0.5

		# Coordenadas exactas de la esfera del reloj en "Mano policia.png" (1920x1080)
		var center := Vector2(
			offset_x + draw_w * (930.0 / 1920.0),
			offset_y + draw_h * (545.0 / 1080.0)
		)
		var radius := draw_h * (108.0 / 1080.0)

		# 1. Arco sombrío de progreso dentro de la esfera del reloj
		var ratio := clampf(overlay.time_left / WatchOverlay.INITIAL_TIME, 0.0, 1.0)
		var start_angle := -PI * 0.5
		var end_angle := start_angle + TAU * ratio
		var arc_color := Color(0.16, 0.15, 0.13, 0.26)
		if overlay.time_left <= 10.0 or overlay.is_rapid_draining:
			arc_color = Color(0.55, 0.10, 0.10, 0.42)
		elif overlay.time_left <= 30.0:
			arc_color = Color(0.38, 0.18, 0.12, 0.34)
		if ratio > 0.001:
			draw_arc(center, radius * 0.78, start_angle, end_angle, 48, arc_color, radius * 0.15, true)

		# 2. Marcas de horas y segundos alrededor del reloj de la ilustración
		var ink_dark := Color(0.13, 0.13, 0.11, 0.88)
		var ink_faint := Color(0.18, 0.18, 0.15, 0.45)
		for i in range(60):
			var a := -PI * 0.5 + float(i) * TAU / 60.0
			var dir := Vector2(cos(a), sin(a))
			if i % 5 == 0:
				var p1 := center + dir * (radius * 0.78)
				var p2 := center + dir * (radius * 0.94)
				draw_line(p1, p2, ink_dark, 2.5, true)
			else:
				var p1 := center + dir * (radius * 0.86)
				var p2 := center + dir * (radius * 0.94)
				draw_line(p1, p2, ink_faint, 1.2, true)

		# 3. Texto digital corriendo dentro de la esfera del reloj
		var font: Font = overlay._custom_font if overlay._custom_font else ThemeDB.fallback_font
		if font:
			var total_sec := int(floor(overlay.time_left))
			var mins := total_sec / 60
			var secs := total_sec % 60
			var centis := int(floor((overlay.time_left - floor(time_left_val(overlay))) * 100.0))
			var watch_str := "%02d:%02d.%02d" % [mins, secs, centis]
			var fsize := maxi(int(radius * 0.25), 11)
			var text_size := font.get_string_size(watch_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize)
			var text_pos := center + Vector2(-text_size.x * 0.5, radius * 0.48)
			draw_string(font, text_pos, watch_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.12, 0.12, 0.10, 0.90))

		# 4. Manecillas corriendo en tiempo real dentro del reloj
		var t := overlay.elapsed_watch_time
		var hour_angle := -PI * 0.5 + (t / 60.0) * (TAU / 12.0) + PI * 0.15
		var min_angle := -PI * 0.5 + (t / 60.0) * TAU
		var sec_angle := -PI * 0.5 + fmod(t, 60.0) * (TAU / 60.0)
		var fast_angle := -PI * 0.5 + fmod(t, 1.0) * TAU

		# Sub-esfera de décimas (arriba del centro)
		var sub_center := center + Vector2(0.0, -radius * 0.34)
		var sub_radius := radius * 0.20
		draw_arc(sub_center, sub_radius, 0.0, TAU, 24, ink_faint, 1.2, true)
		draw_line(sub_center, sub_center + Vector2(cos(fast_angle), sin(fast_angle)) * (sub_radius * 0.85), Color(0.46, 0.10, 0.10, 0.90), 1.6, true)

		# Manecilla corta (horas)
		var hour_dir := Vector2(cos(hour_angle), sin(hour_angle))
		draw_line(center - hour_dir * (radius * 0.12), center + hour_dir * (radius * 0.48), ink_dark, 4.0, true)

		# Manecilla larga (minutos)
		var min_dir := Vector2(cos(min_angle), sin(min_angle))
		draw_line(center - min_dir * (radius * 0.15), center + min_dir * (radius * 0.72), ink_dark, 3.0, true)

		# Segundero carmesí sombrío corriendo
		var sec_dir := Vector2(cos(sec_angle), sin(sec_angle))
		draw_line(center - sec_dir * (radius * 0.20), center + sec_dir * (radius * 0.84), Color(0.48, 0.10, 0.10, 0.95), 2.2, true)

		# Perno central del reloj
		draw_circle(center, radius * 0.06, ink_dark)
		draw_circle(center, radius * 0.03, Color(0.48, 0.10, 0.10, 1.0))

	func time_left_val(ov: WatchOverlay) -> float:
		return ov.time_left
