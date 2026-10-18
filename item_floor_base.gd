extends Area2D
class_name ItemFloor

@export var weapon_to_equiped: PackedScene

@onready var sprite = $Sprite2D
var character_in = null
var can_take = false

func _on_body_entered(body: Node2D) -> void:
	if body is Character or body.has_method("equip_weapon"):
		character_in = body
		can_take = true
		print("Preiona E para tomarlo")

func _on_body_exited(body: Node2D) -> void:
	if body == character_in:
		character_in = null
		can_take = false
		print("Fuera de Rango")

func _input(event: InputEvent) -> void:
	if can_take and event.is_action_pressed("interact"):
		take_weapon()
		
func take_weapon():
	print("Tomando Arma")
	if character_in and weapon_to_equiped:
		if character_in.inventory_ui:
			var weapon_instant = weapon_to_equiped.instantiate() 
			var weapon_sprite = weapon_instant.get_node_or_null("Sprite2D")
			character_in.inventory_ui.add_weapon(weapon_sprite.texture, weapon_to_equiped)
			character_in.equip_weapon(weapon_to_equiped)
		queue_free()
