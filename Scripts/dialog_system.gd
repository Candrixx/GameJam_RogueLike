extends CanvasLayer

@onready var caja = $Caja
@onready var texto = $Caja/Texto

# Guardará la marca de tiempo de la CPU
var tiempo_apertura: int = 0 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	caja.hide()

func mostrar_texto(mensaje: String) -> void:
	caja.show()
	texto.text = mensaje
	get_tree().paused = true 
	
	# Leemos el reloj del sistema y guardamos el milisegundo exacto de apertura
	tiempo_apertura = Time.get_ticks_msec()

func _input(event: InputEvent) -> void:
	if not caja.visible:
		return
		
	# EL ESCUDO: Si no han pasado al menos 300 milisegundos (0.3 segs), es un input fantasma. Lo ignoramos.
	if Time.get_ticks_msec() - tiempo_apertura < 300:
		return
		
	var es_clic_raton = (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_LEFT) and event.pressed
	var es_tecla_aceptar = event.is_action_pressed("ui_accept")
	
	if es_clic_raton or es_tecla_aceptar:
		caja.hide()
		get_tree().paused = false 
		get_viewport().set_input_as_handled()
