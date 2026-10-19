extends Area2D

@onready var note_ui: CanvasLayer = $CanvasLayer
var player_inside: bool = false

func _ready() -> void:
	note_ui.visible = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		if not note_ui.visible:
			note_ui.visible = true
		else:
			GameManager.next_cicle()
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "character":
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "character":
		player_inside = false
		note_ui.visible = false
