extends Area2D
class_name ItemFloor

@export var weapon_to_equiped: PackedScene

var character_in = null
var can_take = false
var _prompt_label: Label = null

func _ready() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] Pick up"
	_prompt_label.custom_minimum_size = Vector2(360, 60)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-180, -145)
	_prompt_label.z_index = 20
	_prompt_label.visible = false
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		_prompt_label.add_theme_font_override("font", load("res://Assets/fonts/SpecialElite-Regular.ttf"))
	_prompt_label.add_theme_font_size_override("font_size", 54)
	_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 0.98))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_prompt_label.add_theme_constant_override("outline_size", 12)
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 4)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 4)
	add_child(_prompt_label)

func _on_body_entered(body: Node2D) -> void:
	if body is Character or body.has_method("equip_weapon"):
		character_in = body
		can_take = true
		if _prompt_label:
			_prompt_label.visible = true
		print("Press E to pick up")

func _on_body_exited(body: Node2D) -> void:
	if body == character_in:
		character_in = null
		can_take = false
		if _prompt_label:
			_prompt_label.visible = false
		print("Out of range")

func _input(event: InputEvent) -> void:
	if can_take and event.is_action_pressed("interact"):
		take_weapon()
		
func take_weapon():
	if not character_in or not weapon_to_equiped:
		return
	if character_in.has_method("add_to_inventory"):
		var icon: Texture2D = null
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			icon = sprite.texture
		if character_in.add_to_inventory(weapon_to_equiped, icon):
			queue_free()
	else:
		character_in.equip_weapon(weapon_to_equiped)
		queue_free()
