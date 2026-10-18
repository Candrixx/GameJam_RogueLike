class_name ArmaBase
extends Area2D

@export var weapon_name: String = "Arma Base"
@export var damage: int = 999
@export var frame_number: int = 0

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func attack_animation():
	print("El arma base ataca genéricamente.")
	if animation_player.has_animation("atacar"):
		animation_player.play("atacar")

func attack():
	if animation_player.is_playing() and animation_player.current_animation == "ataque":
		return
	
	attack_animation()

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		print("Choco contra la pared")
