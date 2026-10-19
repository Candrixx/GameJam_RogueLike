class_name EnemyBase

extends CharacterBody2D

enum State { PATROL, WAIT, CHASE, SEARCH }

# Variables de vision
@export var fov_degrees: float = 360.0
@export var view_distance: float = 760.0
@export var player_group: StringName = &"player"

# Variables de movimiento (lentos en Fase 1 para que el protagonista pueda esquivarlos sin matarlos)
@export var patrol_speed: float = 65.0
@export var chase_speed: float = 185.0
@export var acceleration: float = 350.0
@export var patrol_radius: float = 110.0
@export var search_timeout: float = 4.5
@export var lost_sight_grace: float = 3.5

# Variables de knockback
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 800.0

# Vida del enemigo
@export var life = 45
var is_dead = false

# Daño
@export var contact_damage = 1

# Pausas de espera
@export var wait_chance: float = 0.45
@export var wait_min: float = 0.8
@export var wait_max: float = 2.2
@export var wait_spin_speed: float = 1.6

var state: State = State.PATROL
var facing_dir: Vector2 = Vector2.DOWN

var _patrol_origin: Vector2
var _patrol_target: Vector2
var _last_known_pos: Vector2
var _search_timer: float = 0.0
var _lost_sight_timer: float = 0.0
var _search_spin: float = 0.0
var _wait_timer: float = 0.0
var _wait_spin: float = 0.0
var _player: Node2D = null
var animated_sprite: AnimatedSprite2D = null

var _base_sprite_scale: Vector2 = Vector2(0.6, 0.6)
var _base_sprite_pos: Vector2 = Vector2.ZERO
var _walk_anim_time: float = 0.0
var _morality_thought_cooldown: float = 0.0

# Insect skittering / crawling footstep audio for moving enemies
var _crawler_audio_player: AudioStreamPlayer2D = null
var _skitter_sound: AudioStreamWAV = null
var _step_interval: float = 0.16
var _step_timer: float = 0.0

func _ready() -> void:
	_patrol_origin = global_position
	_pick_patrol_target()
	_walk_anim_time = randf() * TAU

	_setup_crawler_audio()

	# Automatically find an AnimatedSprite2D anywhere in this enemy's scene tree
	animated_sprite = find_child("*AnimatedSprite2D*", true, false) as AnimatedSprite2D
	if animated_sprite:
		_base_sprite_scale = animated_sprite.scale
		_base_sprite_pos = animated_sprite.position
		_setup_phase_frames()
		_update_enemy_sprite()

	add_to_group("enemy")

func _setup_crawler_audio() -> void:
	_crawler_audio_player = AudioStreamPlayer2D.new()
	_crawler_audio_player.max_distance = 850.0
	_crawler_audio_player.attenuation = 1.35
	_crawler_audio_player.volume_db = -8.0
	add_child(_crawler_audio_player)
	_skitter_sound = _generate_insect_skitter_wav()

func _generate_insect_skitter_wav() -> AudioStreamWAV:
	# Generates an organic insect / spider leg skitter click with quick high-frequency chitin scuttle
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	var mix_rate := 22050
	wav.mix_rate = mix_rate
	wav.stereo = false
	var duration := 0.042
	var total_samples := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var f1 := 2400.0
	var f2 := 3600.0
	for i in range(total_samples):
		var t := float(i) / float(mix_rate)
		var env := exp(-t * 90.0)
		var sample_f := (sin(TAU * f1 * t) * 0.5 + sin(TAU * f2 * t) * 0.35 + (randf() * 2.0 - 1.0) * 0.25) * env
		var s_val := int(clampf(sample_f, -1.0, 1.0) * 24000.0)
		bytes.encode_s16(i * 2, s_val)

	wav.data = bytes
	return wav

func _setup_phase_frames() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	var is_phase_two := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		is_phase_two = (GameManager.current_phase == 2)

	var front_path := "res://Assets/sprites/enemies/common/fase 2.png" if is_phase_two else "res://Assets/sprites/enemies/common/fase 1.png"
	var back_path := "res://Assets/sprites/enemies/common/fase 2 espalda.png" if is_phase_two else "res://Assets/sprites/enemies/common/fase 1 espalda.png"

	if ResourceLoader.exists(front_path) and ResourceLoader.exists(back_path):
		var front_tex := load(front_path) as Texture2D
		var back_tex := load(back_path) as Texture2D
		var sf := animated_sprite.sprite_frames.duplicate() as SpriteFrames
		if sf.has_animation("walk_down"):
			sf.clear("walk_down")
		else:
			sf.add_animation("walk_down")
		sf.add_frame("walk_down", front_tex)

		if sf.has_animation("walk_up"):
			sf.clear("walk_up")
		else:
			sf.add_animation("walk_up")
		sf.add_frame("walk_up", back_tex)
		animated_sprite.sprite_frames = sf

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _morality_thought_cooldown > 0.0:
		_morality_thought_cooldown = maxf(0.0, _morality_thought_cooldown - delta)

	_player = get_tree().get_first_node_in_group(player_group)
	if _player and (_player.get("is_reading_intro") or _player.get("is_dead")):
		velocity = Vector2.ZERO
		return

	var sees_player := _player != null and can_see_player(_player)

	# Trigger short morality thoughts when the protagonist gets close to an enemy
	if _player and _morality_thought_cooldown <= 0.0:
		var dist_to_player := global_position.distance_to(_player.global_position)
		if dist_to_player <= 460.0 and sees_player:
			if _player.has_method("trigger_enemy_morality_thought"):
				_player.trigger_enemy_morality_thought()
				_morality_thought_cooldown = 12.0

	if knockback_velocity.length() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
		_animate_walk_motion(delta)
		return
	else:
		knockback_velocity = Vector2.ZERO

	match state:
		State.PATROL:
			if sees_player:
				_enter_chase()
			else:
				_do_patrol(delta)

		State.WAIT:
			if sees_player:
				_enter_chase()
			else:
				_do_wait(delta)

		State.CHASE:
			if sees_player:
				_last_known_pos = _player.global_position
				_lost_sight_timer = 0.0
				_move_toward_point(_last_known_pos, chase_speed, delta)
			else:
				_lost_sight_timer += delta
				if _lost_sight_timer < lost_sight_grace:
					_move_toward_point(_last_known_pos, chase_speed, delta)
				else:
					_enter_search()

		State.SEARCH:
			_search_timer -= delta
			if sees_player:
				_enter_chase()
			elif _search_timer <= 0.0:
				state = State.PATROL
				_pick_patrol_target()
			else:
				_do_search(delta)

	move_and_slide()
	_animate_walk_motion(delta)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.has_method("take_damage") and collider.is_in_group(player_group):
			collider.take_damage(contact_damage)

func _animate_walk_motion(delta: float) -> void:
	if not animated_sprite:
		return
	var spd := velocity.length()
	if spd > 10.0:
		var freq := clampf(spd / 26.0, 4.5, 9.5)
		_walk_anim_time += delta * freq
		var bob_y := absf(sin(_walk_anim_time)) * -10.0
		var sway_rot := sin(_walk_anim_time) * 0.055
		animated_sprite.position = _base_sprite_pos + Vector2(0.0, bob_y)
		animated_sprite.rotation = sway_rot

		# Insect / crawler skitter sound effect playback in Phase 2
		var is_p2 := false
		if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
			is_p2 = (GameManager.current_phase == 2)
		if is_p2:
			_step_timer -= delta
			if _step_timer <= 0.0 and _crawler_audio_player and _skitter_sound:
				_step_timer = randf_range(0.12, 0.18)
				_crawler_audio_player.pitch_scale = randf_range(0.85, 1.25)
				_crawler_audio_player.stream = _skitter_sound
				_crawler_audio_player.play()
	else:
		animated_sprite.position = animated_sprite.position.lerp(_base_sprite_pos, delta * 8.0)
		animated_sprite.rotation = lerpf(animated_sprite.rotation, 0.0, delta * 8.0)

# Vision

func can_see_player(player: Node2D) -> bool:
	var eyes_pos := global_position
	var target_pos := player.global_position
	var dist := eyes_pos.distance_to(target_pos)

	if dist > view_distance:
		return false

	var dir_to_player := eyes_pos.direction_to(target_pos)
	if fov_degrees < 359.0:
		var half_fov_cos := cos(deg_to_rad(fov_degrees / 2.0))
		if facing_dir.dot(dir_to_player) < half_fov_cos and dist > 260.0:
			return false

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(eyes_pos, target_pos, 1 | 8) # Layer 1 (Characters) + Layer 4 (Map/Obstacles = bit 8)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)

	if not result:
		return true

	var hit = result.collider
	while hit:
		if hit == player:
			return true
		hit = hit.get_parent()
	return false

# Estados

func _enter_chase() -> void:
	state = State.CHASE
	if _player:
		_last_known_pos = _player.global_position
	_lost_sight_timer = 0.0

func _enter_search() -> void:
	state = State.SEARCH
	_search_timer = search_timeout
	_search_spin = facing_dir.angle()

func _enter_wait() -> void:
	state = State.WAIT
	_wait_timer = randf_range(wait_min, wait_max)
	_wait_spin = facing_dir.angle()

func _do_patrol(delta: float) -> void:
	if global_position.distance_to(_patrol_target) < 16.0 or is_on_wall():
		if randf() < wait_chance:
			_enter_wait()
		else:
			_pick_patrol_target()
	_move_toward_point(_patrol_target, patrol_speed, delta)

func _do_wait(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	_wait_timer -= delta

	if wait_spin_speed > 0.0:
		_wait_spin += wait_spin_speed * delta
		_facing_from_angle(_wait_spin)

	if _wait_timer <= 0.0:
		state = State.PATROL
		_pick_patrol_target()

func _do_search(delta: float) -> void:
	if global_position.distance_to(_last_known_pos) > 24.0:
		_move_toward_point(_last_known_pos, patrol_speed, delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		_search_spin += delta * 3.0
		_facing_from_angle(_search_spin)

# Movimiento

func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(patrol_radius * 0.35, patrol_radius)
	_patrol_target = _patrol_origin + Vector2(cos(angle), sin(angle)) * dist

func _move_toward_point(target: Vector2, speed: float, delta: float) -> void:
	var dir := (target - global_position)
	if dir.length() < 2.0:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		return

	dir = dir.normalized()
	velocity = velocity.move_toward(dir * speed, acceleration * delta)
	_facing_from_vector(dir)

# Knockback

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

# Daño

func take_damage(damage: int, attacker: Node2D = null) -> void:
	if is_dead:
		return

	life -= damage
	print(self.name, " remaining life: ", life)

	# If hit from behind/distance, track the attacker's position and trigger chase state
	if not attacker:
		attacker = get_tree().get_first_node_in_group(player_group)
	
	if attacker:
		_last_known_pos = attacker.global_position
		if attacker.has_method("register_damage_dealt"):
			attacker.register_damage_dealt(damage)
	
	_enter_chase()
	_spawn_hit_visuals()

	if life <= 0:
		die()

func _spawn_hit_visuals() -> void:
	# 1. Red flash + squash/shake on sprite (no percentage or health bar)
	if animated_sprite:
		var base_scale := _base_sprite_scale
		var tween := create_tween()
		animated_sprite.modulate = Color(2.4, 0.22, 0.22, 1.0)
		tween.tween_property(animated_sprite, "scale", base_scale * Vector2(1.16, 0.86), 0.05)
		tween.parallel().tween_property(animated_sprite, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.08)
		tween.tween_property(animated_sprite, "scale", base_scale, 0.10).set_trans(Tween.TRANS_BOUNCE)
		tween.parallel().tween_property(animated_sprite, "modulate", Color.WHITE, 0.12)

	# 2. Somber blood / dark impact splatter particles
	var particles := CPUParticles2D.new()
	particles.position = Vector2(0, -20)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.38
	particles.explosiveness = 0.92
	particles.spread = 180.0
	particles.gravity = Vector2(0, 260)
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 240.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 9.0
	particles.color = Color(0.58, 0.06, 0.09, 0.92)
	add_child(particles)
	get_tree().create_timer(0.5).timeout.connect(particles.queue_free)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	GameManager.add_kill()

	var collider = find_child("*CollisionShape2D*", true, false) as CollisionShape2D
	if collider:
		collider.set_deferred("disabled", true)

	if animated_sprite:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.35)

		await tween.finished
	queue_free()

# Facing & Sprites

func _facing_from_vector(v: Vector2) -> void:
	if v.length_squared() < 0.0001:
		return
	facing_dir = v.normalized()
	_update_enemy_sprite()

func _update_enemy_sprite() -> void:
	if not animated_sprite:
		return

	# Flip horizontally based on horizontal look component
	if absf(facing_dir.x) > 0.12:
		animated_sprite.flip_h = (facing_dir.x < 0.0)

	# Show back sprite ("walk_up" -> fase 1 espalda.png) when looking up,
	# and front sprite ("walk_down" -> fase 1.png) when looking down/forward
	if facing_dir.y < -0.18:
		if animated_sprite.animation != &"walk_up":
			animated_sprite.play("walk_up")
	else:
		if animated_sprite.animation != &"walk_down":
			animated_sprite.play("walk_down")

func _facing_from_angle(a: float) -> void:
	_facing_from_vector(Vector2(cos(a), sin(a)))
