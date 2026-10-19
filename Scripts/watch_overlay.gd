class_name WatchOverlay
extends CanvasLayer

const WATCH_TEXTURE_PATH := "res://Assets/reloj/Mano policia.png"
const CUSTOM_FONT_PATH := "res://Assets/fonts/SpecialElite-Regular.ttf"
const INITIAL_TIME := 240.0 # 4 minutes in seconds

var is_open: bool = false
var countdown_started: bool = false
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
var _timer_label: Label
var _sub_label: Label
var _fade_tween: Tween = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(CUSTOM_FONT_PATH):
		_custom_font = load(CUSTOM_FONT_PATH)
	_build_ui()
	_root_control.visible = false
	_root_control.modulate.a = 0.0

func start_countdown() -> void:
	countdown_started = true

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

	var title_lbl := Label.new()
	title_lbl.text = "Hurry, find the exit"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _custom_font:
		title_lbl.add_theme_font_override("font", _custom_font)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.66, 0.63, 0.58, 0.92))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title_lbl)

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

func _input(event: InputEvent) -> void:
	if _timeout_triggered:
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

func _process(delta: float) -> void:
	if character and (character.get("is_reading_intro") or character.get("is_dead")):
		return
	if countdown_started and not _timeout_triggered:
		elapsed_watch_time += delta
		if time_left > 0.0:
			time_left = maxf(time_left - delta, 0.0)
			if time_left <= 0.0:
				time_left = 0.0
				_timeout_triggered = true
				force_close()
				if character and character.has_method("die_from_timeout"):
					character.die_from_timeout()

	if _root_control.visible:
		_update_timer_label()
		_dial_drawer.queue_redraw()

func _update_timer_label() -> void:
	var total_sec := int(floor(time_left))
	var mins := total_sec / 60
	var secs := total_sec % 60
	var centis := int(floor((time_left - floor(time_left)) * 100.0))
	_timer_label.text = "%02d:%02d.%02d" % [mins, secs, centis]

	if time_left <= 10.0:
		var pulse := 0.5 + 0.5 * sin(elapsed_watch_time * 10.0)
		_timer_label.add_theme_color_override("font_color", Color(0.62 + 0.15 * pulse, 0.12, 0.12, 0.98))
	elif time_left <= 25.0:
		_timer_label.add_theme_color_override("font_color", Color(0.68, 0.42, 0.28, 0.95))
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

		# 1. Arco sombrío de progreso del minuto dentro de la esfera del reloj
		var ratio := clampf(overlay.time_left / WatchOverlay.INITIAL_TIME, 0.0, 1.0)
		var start_angle := -PI * 0.5
		var end_angle := start_angle + TAU * ratio
		var arc_color := Color(0.16, 0.15, 0.13, 0.26)
		if overlay.time_left <= 10.0:
			arc_color = Color(0.45, 0.10, 0.10, 0.36)
		elif overlay.time_left <= 25.0:
			arc_color = Color(0.32, 0.18, 0.12, 0.30)
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
