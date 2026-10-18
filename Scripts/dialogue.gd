extends CanvasLayer

# --- PUNTEROS A TUS NODOS EXACTOS ---
# Actualizados con los nombres de tu imagen
@onready var cont_dialogo = $ContDialogo
@onready var texto_rico = $ContDialogo/MargenInt/OrgaVertical/Dialogo
@onready var retrato = $Personaje # Agregado para poder ocultarlo/mostrarlo

# --- VARIABLES DE MEMORIA ---
var lista_textos: Array = []
var indice_actual: int = 0
var tween_maquina_escribir: Tween

func _ready() -> void:
	# 1. Ocultamos la interfaz y el dibujo al inicio
	cont_dialogo.hide()
	retrato.hide()
	
	# 2. VITAL: Ignorar la pausa global
	process_mode = Node.PROCESS_MODE_ALWAYS 

# --- FUNCIÓN DE ENTRADA ---
func iniciar_conversacion(nuevos_textos: Array) -> void:
	lista_textos = nuevos_textos
	indice_actual = 0
	
	# Congelamos el mundo y mostramos la interfaz
	get_tree().paused = true
	cont_dialogo.show()
	retrato.show()
	
	_dibujar_linea_actual()

# --- LÓGICA DE RENDERIZADO ---
func _dibujar_linea_actual() -> void:
	texto_rico.text = lista_textos[indice_actual]
	texto_rico.visible_characters = 0
	
	if tween_maquina_escribir:
		tween_maquina_escribir.kill()
		
	tween_maquina_escribir = create_tween()
	
	var tiempo_total = lista_textos[indice_actual].length() * 0.03
	tween_maquina_escribir.tween_property(texto_rico, "visible_characters", lista_textos[indice_actual].length(), tiempo_total)

# --- ESCUCHA DE TECLADO/MOUSE ---
func _input(event: InputEvent) -> void:
	if not cont_dialogo.visible:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click_izquierdo"): 
		
		if texto_rico.visible_characters < lista_textos[indice_actual].length():
			# Skipping (Terminar de escribir de golpe)
			if tween_maquina_escribir:
				tween_maquina_escribir.kill()
			texto_rico.visible_characters = lista_textos[indice_actual].length()
			
		else:
			indice_actual += 1
			
			if indice_actual < lista_textos.size():
				_dibujar_linea_actual()
			else:
				_cerrar_sistema()

func _cerrar_sistema() -> void:
	cont_dialogo.hide()
	retrato.hide()
	lista_textos.clear() 
	get_tree().paused = false
