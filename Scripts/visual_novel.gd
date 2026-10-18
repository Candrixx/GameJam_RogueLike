extends CanvasLayer

func _terminar_novela_visual() -> void:
	# 1. Descongelamos el mundo para que el jugador y los enemigos vuelvan a moverse
	get_tree().paused = false
	
	# 2. Liberamos la memoria dinámica
	# El equivalente a "delete this;" en C++. Destruye el CanvasLayer, los retratos 
	# y el texto, devolviendo la RAM al sistema.
	queue_free()
