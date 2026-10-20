extends Area2D

@onready var note_ui: CanvasLayer = $CanvasLayer
var player_inside: bool = false
var _triggered: bool = false
var _prompt_label: Label = null

func _ready() -> void:
	note_ui.visible = false
	_setup_note_glow()
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

func _setup_note_glow() -> void:
	var glow_tex := _create_sparkle_glow_texture(128)

	# PointLight2D so the flashback note casts a warm noticeable halo around itself on the floor
	var pt_light := PointLight2D.new()
	pt_light.name = "NoteGlowLight"
	pt_light.texture = glow_tex
	pt_light.texture_scale = 2.4
	pt_light.color = Color(1.0, 0.94, 0.76, 1.0)
	pt_light.energy = 1.05
	add_child(pt_light)

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	var aura := Sprite2D.new()
	aura.name = "GlowAura"
	aura.texture = glow_tex
	aura.material = mat
	aura.modulate = Color(1.0, 0.93, 0.68, 0.80)
	aura.scale = Vector2(1.55, 1.55)
	aura.z_index = -1
	add_child(aura)

	var star_tex := _create_star_glint_texture(96)
	var glint := Sprite2D.new()
	glint.name = "GlowGlint"
	glint.texture = star_tex
	glint.material = mat
	glint.modulate = Color(1.0, 0.98, 0.85, 0.90)
	glint.scale = Vector2(1.25, 1.25)
	glint.z_index = 1
	add_child(glint)

	var note_spr := get_node_or_null("Sprite2D") as Sprite2D
	if note_spr:
		var spr_mat := CanvasItemMaterial.new()
		spr_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		note_spr.material = spr_mat

	var tw := create_tween().set_loops()
	tw.set_parallel(true)
	tw.tween_property(aura, "scale", Vector2(1.95, 1.95), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glint, "scale", Vector2(1.55, 1.55), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(pt_light, "energy", 1.35, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_property(aura, "scale", Vector2(1.40, 1.40), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glint, "scale", Vector2(0.95, 0.95), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(pt_light, "energy", 0.80, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var rot_tw := create_tween().set_loops()
	rot_tw.tween_property(glint, "rotation", TAU, 5.5)

func _create_sparkle_glow_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(center) / max_r
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.2)
			var ring := exp(-pow((d - 0.52) / 0.14, 2.0)) * 0.45
			var final_a := clampf(a * 0.78 + ring, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, final_a))
	return ImageTexture.create_from_image(img)

func _create_star_glint_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in range(size):
		for x in range(size):
			var dx := absf(float(x) - c) / c
			var dy := absf(float(y) - c) / c
			var dist := sqrt(dx * dx + dy * dy)
			if dist > 1.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
				continue
			var cross_1 := exp(-dx * 16.0) * exp(-dy * 2.6) + exp(-dy * 16.0) * exp(-dx * 2.6)
			var diag_x := absf((float(x) - c) + (float(y) - c)) / (c * 1.414)
			var diag_y := absf((float(x) - c) - (float(y) - c)) / (c * 1.414)
			var cross_2 := (exp(-diag_x * 20.0) * exp(-diag_y * 3.8) + exp(-diag_y * 20.0) * exp(-diag_x * 3.8)) * 0.55
			var radial_fade := clampf(1.0 - dist, 0.0, 1.0)
			var alpha := clampf((cross_1 + cross_2) * radial_fade * 0.68, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	if _triggered:
		return
	if player_inside and Input.is_action_just_pressed("interact"):
		_triggered = true
		if _prompt_label:
			_prompt_label.visible = false
		var player := get_tree().get_first_node_in_group("player")
		if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") == 2:
			if GameManager.has_method("unlock_phase_two_barrier"):
				GameManager.unlock_phase_two_barrier()
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
