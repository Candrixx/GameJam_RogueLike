extends Area2D
class_name ItemFloor

@export var weapon_to_equiped: PackedScene
@export var item_id: String

var character_in = null
var can_take = false
var _prompt_label: Label = null

func _ready() -> void:
	if get_node_or_null("/root/GameManager"):
		if item_id in GameManager.collected_item_ids:
			queue_free()
			return
		# The baton ("Batoon") only appears starting in Phase 2
		if item_id == "Batoon" and GameManager.get("current_phase") != 2:
			queue_free()
			return

	_setup_item_glow()

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

func _setup_item_glow() -> void:
	var glow_tex := _create_sparkle_glow_texture(128)

	# Soft PointLight2D so the object illuminates the floor around itself in the dark
	var pt_light := PointLight2D.new()
	pt_light.name = "ItemGlowLight"
	pt_light.texture = glow_tex
	pt_light.texture_scale = 2.2
	pt_light.color = Color(1.0, 0.93, 0.72, 1.0)
	pt_light.energy = 0.95
	add_child(pt_light)

	# Unshaded additive halo behind the item sprite
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	var aura := Sprite2D.new()
	aura.name = "GlowAura"
	aura.texture = glow_tex
	aura.material = mat
	aura.modulate = Color(1.0, 0.92, 0.65, 0.75)
	aura.scale = Vector2(1.45, 1.45)
	aura.z_index = -1
	add_child(aura)

	# Second rotating star-glint overlay for a noticeable shimmer
	var star_tex := _create_star_glint_texture(96)
	var glint := Sprite2D.new()
	glint.name = "GlowGlint"
	glint.texture = star_tex
	glint.material = mat
	glint.modulate = Color(1.0, 0.97, 0.82, 0.85)
	glint.scale = Vector2(1.15, 1.15)
	glint.z_index = 1
	add_child(glint)

	# Make the item sprite itself slightly self-lit so it stands out clearly
	var item_spr := get_node_or_null("Sprite2D") as Sprite2D
	if item_spr:
		var spr_mat := CanvasItemMaterial.new()
		spr_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		item_spr.material = spr_mat

	var tw := create_tween().set_loops()
	tw.set_parallel(true)
	tw.tween_property(aura, "scale", Vector2(1.85, 1.85), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "modulate:a", 0.98, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glint, "scale", Vector2(1.45, 1.45), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(pt_light, "energy", 1.25, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_property(aura, "scale", Vector2(1.35, 1.35), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "modulate:a", 0.52, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glint, "scale", Vector2(0.92, 0.92), 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(pt_light, "energy", 0.75, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var rot_tw := create_tween().set_loops()
	rot_tw.tween_property(glint, "rotation", TAU, 6.0)

func _create_sparkle_glow_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(center) / max_r
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.2)
			# Soft bright ring near 0.55 radius for an unmistakable halo around the item
			var ring := exp(-pow((d - 0.52) / 0.14, 2.0)) * 0.42
			var final_a := clampf(a * 0.75 + ring, 0.0, 1.0)
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
			var alpha := clampf((cross_1 + cross_2) * radial_fade * 0.65, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

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
			if get_node_or_null("/root/GameManager"):
				GameManager.collected_item_ids.append(item_id)
			queue_free()
	else:
		character_in.equip_weapon(weapon_to_equiped)
		queue_free()
