extends Control

@onready var cortina = $CortinaTrnas
@onready var caja_botones = $CajaBotones
@onready var panel_creditos = $PanelCreditos

func _ready() -> void:
	_setup_english_ui()
	if get_node_or_null("/root/GameManager") and GameManager.get("open_credits_on_menu") == true:
		GameManager.open_credits_on_menu = false
		caja_botones.hide()
		panel_creditos.show()
		if GameManager.has_method("play_music"):
			GameManager.play_music(GameManager.MUSIC_CAMINO_BUENO)
	elif get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
		GameManager.play_music(GameManager.MUSIC_TENSA_CALMA)

func _setup_english_ui() -> void:
	var custom_font: FontFile = null
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		custom_font = load("res://Assets/fonts/SpecialElite-Regular.ttf")

	var btn_map := {
		"Jugar": "Play",
		"Creditos": "Credits",
		"Salir": "Exit"
	}
	for node_name in btn_map.keys():
		var btn := caja_botones.get_node_or_null(node_name) as Button
		if btn:
			btn.icon = null
			btn.text = btn_map[node_name]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if custom_font:
				btn.add_theme_font_override("font", custom_font)
			btn.add_theme_font_size_override("font_size", 46)
			btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.98))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.18, 0.20, 1.0))
			btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))

	# Ensure right-to-left black-to-transparent gradient exists behind the team names in Credits
	if panel_creditos and not panel_creditos.get_node_or_null("DegradadoCreditos"):
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		grad.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.78), Color(0, 0, 0, 0.98)])
		var grad_tex := GradientTexture2D.new()
		grad_tex.gradient = grad
		grad_tex.fill_from = Vector2(0.0, 0.5)
		grad_tex.fill_to = Vector2(1.0, 0.5)
		var grad_rect := TextureRect.new()
		grad_rect.name = "DegradadoCreditos"
		grad_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		grad_rect.anchor_left = 0.30
		grad_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grad_rect.texture = grad_tex
		grad_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel_creditos.add_child(grad_rect)
		var fondo2 := panel_creditos.get_node_or_null("Fondo2")
		if fondo2:
			panel_creditos.move_child(grad_rect, fondo2.get_index() + 1)

	# Translate Credits screen headings while keeping the real team list
	var texto_creditos := panel_creditos.get_node_or_null("creditos") as RichTextLabel
	if texto_creditos:
		if custom_font:
			texto_creditos.add_theme_font_override("normal_font", custom_font)
			texto_creditos.add_theme_font_override("bold_font", custom_font)
		texto_creditos.text = "Artists\n\n\tChris Ferreira \"chrisit0\"\n\tAvril Paredes \"Avrillll\"\n\tAndrea Albornoz \"HoneyJoo\"\n\tMariangel De Oliveira \"Lil kitty\"\n\tVanesa Martínez \"Vanesamb\"\n\tMariangel Gonzalez \"MAOGUI\"\n\nProgrammers\n\tCarlos Heydra \"Artificial_wiimote\"\n\tDiego De Leon \"Daigo\"\n\tRicardo Angulo \"Uraviry\"\n\tCarlos Arena \"Candrixx\"\n\tDiego Monsalve \"Sparatrox\"\n\nWriter\n\tkamilah \"kamilah\"\n\nMusic & Sound\n\tFrancisco Guevara \"Allrisk\""

	var volver_btn := panel_creditos.get_node_or_null("Volver") as Button
	if volver_btn:
		volver_btn.icon = null
		volver_btn.text = "Back"
		if custom_font:
			volver_btn.add_theme_font_override("font", custom_font)
		volver_btn.add_theme_font_size_override("font_size", 48)
		volver_btn.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86, 0.98))
		volver_btn.add_theme_color_override("font_hover_color", Color(0.88, 0.22, 0.22, 1.0))

func _on_jugar_pressed() -> void:
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().change_scene_to_file("res://Scenes/ui/loadingScreen.tscn")



func _on_creditos_pressed() -> void:
	if get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
		GameManager.play_music(GameManager.MUSIC_TENSA_CALMA)
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Tween de ida (Oscurecer)
	var tween_ida = create_tween()
	tween_ida.tween_property(cortina, "modulate:a", 1.0, 0.4)
	await tween_ida.finished
	
	# Intercambio de interfaces en la oscuridad
	$CajaBotones.hide()
	$PanelCreditos.show()
	
	# Tween de regreso (Aclarar)
	var tween_regreso = create_tween()
	tween_regreso.tween_property(cortina, "modulate:a", 0.0, 0.4)
	await tween_regreso.finished
	
	# Liberamos el input
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE




func _on_salir_pressed() -> void:
	get_tree().quit()



func _on_volver_pressed() -> void:
	# 1. Bloqueamos clics
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 2. Fundido a negro
	var tween_ida = create_tween()
	tween_ida.tween_property(cortina, "modulate:a", 1.0, 0.4)
	await tween_ida.finished
	
	# 3. EL CAMBIO (Invertido)
	# Escondemos los créditos y volvemos a encender el menú principal
	panel_creditos.hide()
	caja_botones.show()
	if get_node_or_null("/root/GameManager") and GameManager.has_method("play_music"):
		GameManager.play_music(GameManager.MUSIC_TENSA_CALMA)
	
	# 4. Fundido a transparente
	var tween_regreso = create_tween()
	tween_regreso.tween_property(cortina, "modulate:a", 0.0, 0.4)
	await tween_regreso.finished
	
	# 5. Liberamos clics
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
