extends Area2D

# Al usar @export_multiline, Godot creará una caja de texto grande en el Inspector 
# que te permitirá presionar 'Enter' y escribir párrafos completos cómodamente.
@export_multiline var texto_del_personaje: String = "Write here..."

var ya_activado: bool = false 

func _on_body_entered(body: Node2D) -> void:
	if ya_activado: 
		return 
	# Skip GatilloDialogo at spawn since Character displays the 2-step clean English notes
	if name == "GatilloDialogo":
		return
		
	if body.name == "character":
		ya_activado = true 
		
		# En lugar del texto de prueba, enviamos la variable al Singleton
		DialogSystem.mostrar_texto(texto_del_personaje)
