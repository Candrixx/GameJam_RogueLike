extends Area2D

@onready var note_ui: CanvasLayer = $CanvasLayer
var player_inside: bool = false
var _triggered: bool = false
var _prompt_label: Label = null

func _ready() -> void:
	note_ui.visible = false
	_prompt_label = Label.new()
	_prompt_label.text = "[E] Read"
	_prompt_label.custom_minimum_size = Vector2(360, 60)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-180, -145)
	_prompt_label.z_index = 20
	_prompt_label.visible = false
	if ResourceLoader.exists("res://Assets/fonts/SpecialElite-Regular.ttf"):
		var f := load("res://Assets/fonts/SpecialElite-Regular.ttf") as FontFile
		_prompt_label.add_theme_font_override("font", f)
		var note_text_lbl := note_ui.get_node_or_null("note_bg/note_text") as Label
		if note_text_lbl:
			note_text_lbl.add_theme_font_override("font", f)
			note_text_lbl.add_theme_font_size_override("font_size", 32)
	_prompt_label.add_theme_font_size_override("font_size", 54)
	_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 0.98))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_prompt_label.add_theme_constant_override("outline_size", 12)
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 4)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 4)
	add_child(_prompt_label)

func _process(_delta: float) -> void:
	if _triggered:
		return
	if player_inside and Input.is_action_just_pressed("interact"):
		_triggered = true
		if _prompt_label:
			_prompt_label.visible = false
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("trigger_flashback_note_drain"):
			player.trigger_flashback_note_drain()
		visible = false
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body.name == "character" or body is Character:
		player_inside = true
		if _prompt_label:
			_prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "character" or body is Character:
		player_inside = false
		note_ui.visible = false
		if _prompt_label:
			_prompt_label.visible = false
