extends Control

@onready var cortina = $CortinaTrnas
@onready var caja_botones = $CajaBotones
@onready var panel_creditos = $PanelCreditos

func _on_jugar_pressed() -> void:
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().change_scene_to_file("res://Scenes/loadingScreen.tscn")



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
