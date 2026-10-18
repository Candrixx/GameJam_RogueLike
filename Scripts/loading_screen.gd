extends Control

@onready var barra_progreso = $BarraProgreso

# La ruta estática del nivel al que queremos ir
var ruta_nivel = "res://Scenes/maps/map_labyrinth.tscn"

# Godot exige que pasemos un Array para inyectar el valor de progreso por referencia 
var progreso = [] 

func _ready() -> void:
	# 1. PETICIÓN ASÍNCRONA
	# Le decimos al sistema operativo que empiece a cargar el archivo en otro hilo.
	# El código sigue de largo instantáneamente, no se bloquea aquí.
	ResourceLoader.load_threaded_request(ruta_nivel)

func _process(delta: float) -> void:
	# 2. VIGILANCIA DE MEMORIA (60 veces por segundo)
	# Le preguntamos a la RAM en qué estado va la carga de esa ruta específica.
	# Al pasarle el array 'progreso', Godot mete ahí un float entre 0.0 y 1.0.
	var estado = ResourceLoader.load_threaded_get_status(ruta_nivel, progreso)
	
	# Si el hilo secundario nos avisa que ya terminó de ensamblar los bytes:
	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		
		# Apagamos este ciclo _process para que no intente cargar 2 veces en el mismo frame
		set_process(false)
		
		# Extraemos el paquete de memoria ya procesado
		var escena_lista = ResourceLoader.load_threaded_get(ruta_nivel)
		
		# Hacemos el salto. Ojo, ya no usamos "change_scene_to_file", 
		# sino "change_scene_to_packed" porque ya tenemos el recurso crudo en las manos.
		get_tree().change_scene_to_packed(escena_lista)
