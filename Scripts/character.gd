class_name Character
extends CharacterBody2D

@export var speed = 450
@export var accelaration = 35

@export var max_life: int = 3
var life: int = 3
var is_dead: bool = false
var is_invulnerable: bool = false

var kill_count = 0

var weapon_equiped: ArmaBase = null
var last_direction = Vector2.DOWN
var is_attacking = false

@onready var point_equipment: Marker2D = $EquipmentPoint
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var attack = Input.is_action_just_pressed("attack")
	
	if attack and weapon_equiped:
		attacking(weapon_equiped.weapon_name)

	if is_attacking or is_dead:
		return
	
	
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.lerp(speed * direction, delta * accelaration)
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	
	if velocity != Vector2.ZERO:
		play_animation(last_direction, "Walk")
	else:
		play_animation(last_direction, "Idle")		
	move_and_slide()

func play_animation(direction: Vector2, prefix: String):
	if direction.x != 0:
		animated_sprite_2d.flip_h = direction.x < 0
		animated_sprite_2d.play(prefix + "_Side")
	elif direction.y < 0:
		animated_sprite_2d.play(prefix + "_Back")
	elif direction.y > 0:
		animated_sprite_2d.play(prefix + "_Front")

func attacking(suffix: String) -> void:
	is_attacking = true
	weapon_equiped.enable_hitbox()
	animated_sprite_2d.play("Attack_" + suffix)
	await animated_sprite_2d.animation_finished
	is_attacking = false
	weapon_equiped.disable_hitbox()

func equip_weapon(new_weapon: PackedScene):
	if weapon_equiped:
		weapon_equiped.queue_free()
		
	weapon_equiped = new_weapon.instantiate() as ArmaBase
	if weapon_equiped:
		point_equipment.add_child(weapon_equiped)
		weapon_equiped.position = Vector2.ZERO
		weapon_equiped.rotation = 0

func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable:
		return

	life -= amount
	print("Player took damage! Life: ", life)

	if life <= 0:
		die()
	else:
		# Brief flash / i-frame window so player doesn't instantly die on touch
		_start_invulnerability(0.8)

# func _start_invulnerability(duration: float) -> void:
# 	is_invulnerable = true
# 	var tween = create_tween().set_loops(4)
# 	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, duration / 8.0)
# 	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, duration / 8.0)
# 	await get_tree().create_timer(duration).timeout
# 	is_invulnerable = false
# 	animated_sprite_2d.modulate.a = 1.0

func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	
	# Create a tween that flashes red and partially transparent
	var tween = create_tween().set_loops(4)
	var flash_color = Color(1.0, 0.2, 0.2, 0.4) # Red tint + transparent
	var normal_color = Color.WHITE
	var step_time = duration / 8.0

	tween.tween_property(animated_sprite_2d, "modulate", flash_color, step_time)
	tween.tween_property(animated_sprite_2d, "modulate", normal_color, step_time)
	
	await get_tree().create_timer(duration).timeout
	
	is_invulnerable = false
	animated_sprite_2d.modulate = Color.WHITE

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	# Disable weapon if one is currently out
	if weapon_equiped and weapon_equiped.has_method("disable_hitbox"):
		weapon_equiped.disable_hitbox()

	# Play the "Die" animation and wait for it to finish
	animated_sprite_2d.play("Die")
	await animated_sprite_2d.animation_finished

	# Small pause before reload for visual pacing
	await get_tree().create_timer(0.5).timeout

	# Reload the current scene
	get_tree().reload_current_scene()

func add_kill() -> void:
	kill_count += 1
	print("Enemies defeated: ", kill_count)
