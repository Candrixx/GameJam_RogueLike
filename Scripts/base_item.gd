class_name ArmaBase
extends Area2D

@export var weapon_name: String = "Arma Base"
@export var damage: int = 999
@export var knockback_force: float = 700.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _hit_targets: Dictionary = {}

func _ready() -> void:
	collision_mask = 15
	collision_shape.disabled = false
	monitoring = false

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		_try_damage_target(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _on_body_entered(body: Node2D) -> void:
	_try_damage_target(body)

func _on_area_entered(area: Area2D) -> void:
	if not area:
		return
	if area.is_in_group("enemy") or area.is_in_group("boss"):
		_try_damage_target(area)
	elif area.get_parent() and (area.get_parent().is_in_group("enemy") or area.get_parent().is_in_group("boss") or area.get_parent().has_method("take_damage")):
		_try_damage_target(area.get_parent())

func _try_damage_target(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return
	var player := get_tree().get_first_node_in_group("player")
	if target == player:
		return
	if not (target.is_in_group("enemy") or target.is_in_group("boss")):
		return
	var id := target.get_instance_id()
	if _hit_targets.has(id):
		return
	_hit_targets[id] = true

	if target is Node2D and target.has_method("apply_knockback"):
		var push_direction: Vector2 = ((target as Node2D).global_position - global_position).normalized()
		if push_direction.length_squared() < 0.001:
			push_direction = Vector2.DOWN
		target.apply_knockback(push_direction * knockback_force)

	if target.has_method("take_damage"):
		target.take_damage(damage)

func enable_hitbox() -> void:
	_hit_targets.clear()
	monitoring = true
	for body in get_overlapping_bodies():
		_try_damage_target(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func disable_hitbox() -> void:
	monitoring = false
	_hit_targets.clear()
