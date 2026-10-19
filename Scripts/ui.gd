extends Control

@onready var cortina = $CortinaTrnas
@onready var caja_botones = $CajaBotones
@onready var panel_creditos = $PanelCreditos

func _ready() -> void:
	_setup_english_ui()

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
		var btn := caja_botones.get_node_or_null(node_name) as TextureButton
		if btn:
			btn.texture_normal = null
			btn.texture_hover = null
			btn.texture_pressed = null
			var lbl := Label.new()
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.text = btn_map[node_name]
			if custom_font:
				lbl.add_theme_font_override("font", custom_font)
			lbl.add_theme_font_size_override("font_size", 46)
			lbl.add_theme_color_override("font_color", Color(0.88, 0.86, 0.84, 0.95))
			lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
			lbl.add_theme_constant_override("shadow_offset_x", 3)
			lbl.add_theme_constant_override("shadow_offset_y", 3)
			btn.add_child(lbl)
			btn.mouse_entered.connect(func(): lbl.add_theme_color_override("font_color", Color(0.85, 0.18, 0.20, 1.0)))
			btn.mouse_exited.connect(func(): lbl.add_theme_color_override("font_color", Color(0.88, 0.86, 0.84, 0.95)))

	# Translate Credits screen
	var texto_creditos := panel_creditos.get_node_or_null("TextoCreditos") as RichTextLabel
	if texto_creditos:
		if custom_font:
			texto_creditos.add_theme_font_override("normal_font", custom_font)
			texto_creditos.add_theme_font_override("bold_font", custom_font)
		texto_creditos.text = "[center][b]DIRECTOR[/b]\nSamuel\n\n[b]PROGRAMMING[/b]\nUn compa\n\n[b]ART & DESIGN[/b]\nAlguien que sabe dibujar\n\n[b]MUSIC[/b]\nKevin MacLeod (probably)\n\n\nThank you for playing![/center]"

	var volver_btn := panel_creditos.get_node_or_null("Volver") as Button
	if volver_btn:
		volver_btn.text = "Back"
		if custom_font:
			volver_btn.add_theme_font_override("font", custom_font)

func _on_jugar_pressed() -> void:
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().change_scene_to_file("res://Scenes/ui/loadingScreen.tscn")



func _on_creditos_pressed() -> void:
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
	
	# 4. Fundido a transparente
	var tween_regreso = create_tween()
	tween_regreso.tween_property(cortina, "modulate:a", 0.0, 0.4)
	await tween_regreso.finished
	
	# 5. Liberamos clics
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
