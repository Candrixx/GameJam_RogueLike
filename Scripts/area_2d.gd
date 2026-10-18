extends Area2D

# Quemamos el arreglo estático en la memoria del nodo
var dialogos_tutorial = [
	"Sistema de traje iniciado. Soporte vital estable.",
	"Usa [W, A, S, D] para calibrar los motores de movimiento.",
    "Detectando anomalías en el sector contiguo... ten cuidado."
]

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		set_deferred("monitoring", false) # Apagamos el área matemáticamente
		
		# Le aventamos el arreglo al Singleton. Él se encarga de pausar el juego.
		DialogSystem.iniciar_conversacion(dialogos_tutorial)
