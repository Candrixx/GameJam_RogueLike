extends CanvasLayer

@onready var h_box_container = $MarginContainer/HBoxContainer
signal weapon_selected(weapon_scene: PackedScene)

func add_weapon(weapon_texture: Texture2D, weapon_scene: PackedScene):
	var slot = TextureButton.new()
	slot.texture_normal = weapon_texture
	
	# 1. Habilitamos ignorar el tamaño original para que respete el tamaño mínimo del contenedor
	slot.ignore_texture_size = true
	
	# 2. Usamos el modo de estiramiento para mantener la proporción centrada
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	slot.custom_minimum_size = Vector2(40, 40) # Ajusta el tamaño de los slots según prefieras
	
	# Conectamos el evento de presionar
	slot.pressed.connect(func(): emit_signal("weapon_selected", weapon_scene))
	
	h_box_container.add_child(slot)
