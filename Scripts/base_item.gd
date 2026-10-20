class_name ArmaBase
extends Area2D

@export var weapon_name: String = "Arma Base"
@export var damage: int = 999
@export var knockback_force: float = 700.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_shape.disabled = false
	monitoring = false

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("apply_knockback"):
		var push_direction: Vector2 = (body.global_position - global_position).normalized()
		body.apply_knockback(push_direction * knockback_force)

		if body.has_method("take_damage"):
			body.take_damage(damage)
			
	if body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

func enable_hitbox() -> void:
	monitoring = true

func disable_hitbox() -> void:
	monitoring = false
