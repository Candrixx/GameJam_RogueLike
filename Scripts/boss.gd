extends CharacterBody2D

enum State { IDLE, ATTACKING, HURT, DEAD }

@export var max_health: int = 280
@export var damage: int = 1
@export var chase_speed: float = 195.0

@export var eye_max_distance: float = 16.0
@export var eye_follow_speed: float = 12.0

var current_health: int
var current_state: State = State.IDLE
var player_ref: Node2D = null
var is_active: bool = false

@onready var visuals: Node2D = $Visuals
@onready var body_sprite: Sprite2D = $Visuals/BodySprite
@onready var head_sprite: Sprite2D = $Visuals/HeadSprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var eye_socket: Marker2D = $Visuals/EyeSocket
@onready var eyes_sprite: Sprite2D = $Visuals/EyeSocket/EyesSprite
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

const ATTACKS = [
	"3rd_leg_attack",
	"double_manotazo"
]

var _base_visuals_pos: Vector2 = Vector2(-16, -50)
var _base_head_pos: Vector2 = Vector2.ZERO
var _base_eye_socket_pos: Vector2 = Vector2(-2, -10)

# Nervous head tic variables
var _tic_timer: float = 0.25
var _tic_spasm_time: float = 0.0
var _tic_target_rot: float = 0.0
var _tic_target_offset: Vector2 = Vector2.ZERO
var _tic_current_rot: float = 0.0
var _tic_current_offset: Vector2 = Vector2.ZERO
var _walk_bob_time: float = 0.0

# Lunge / Knockback variables
var _lunge_velocity: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _slash_triggered_in_anim: bool = false
var _second_slash_triggered: bool = false

# Boss complementary voice/sound players ("audio boss 1.mp3" <-> "audio boss 2.mp3") with crossfade fusion & Labyrinth Echo
const BOSS_PEAK_VOLUME_DB: float = 9.5
const BOSS_CROSSFADE_TIME: float = 1.35

var _boss_voice_player_a: AudioStreamPlayer2D = null
var _boss_voice_player_b: AudioStreamPlayer2D = null
var _boss_audio_1: AudioStream = null
var _boss_audio_2: AudioStream = null
var _active_boss_slot: int = 0 # 0 = player_a (audio 1), 1 = player_b (audio 2)
var _is_crossfading_boss_audio: bool = false
var _crossfade_elapsed: float = 0.0
var _crossfade_duration: float = BOSS_CROSSFADE_TIME

func _ready() -> void:
	add_to_group("boss")
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("player")
	_setup_boss_complementary_audio()

	if visuals:
		_base_visuals_pos = visuals.position
	if head_sprite:
		_base_head_pos = head_sprite.position
	if eye_socket:
		_base_eye_socket_pos = eye_socket.position

	attack_timer.one_shot = true
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	if not attack_hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		attack_hitbox.body_entered.connect(_on_hitbox_body_entered)

	var in_phase_3 := false
	if get_node_or_null("/root/GameManager") and GameManager.get("current_phase") != null:
		in_phase_3 = (GameManager.current_phase == 3)

	if in_phase_3:
		activate_boss()
	else:
		_deactivate_boss()

func _load_boss_audio_stream(base_res_path_no_ext: String) -> AudioStream:
	var mp3_res := base_res_path_no_ext + ".mp3"
	var mp3_global := ProjectSettings.globalize_path(mp3_res)
	if FileAccess.file_exists(mp3_global):
		var bytes := FileAccess.get_file_as_bytes(mp3_global)
		if not bytes.is_empty():
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			mp3.loop = false
			return mp3
	if ResourceLoader.exists(mp3_res):
		var st := load(mp3_res) as AudioStream
		if st is AudioStreamMP3:
			(st as AudioStreamMP3).loop = false
		if st:
			return st

	var ogg_res := base_res_path_no_ext + ".ogg"
	var ogg_global := ProjectSettings.globalize_path(ogg_res)
	if FileAccess.file_exists(ogg_global):
		var ogg := AudioStreamOggVorbis.load_from_file(ogg_global)
		if ogg:
			ogg.loop = false
			return ogg
	if ResourceLoader.exists(ogg_res):
		var st_ogg := load(ogg_res) as AudioStream
		if st_ogg is AudioStreamOggVorbis:
			(st_ogg as AudioStreamOggVorbis).loop = false
		return st_ogg
	return null

func _create_boss_voice_player(node_name: String) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.name = node_name
	p.max_distance = 7500.0
	p.attenuation = 0.25
	p.panning_strength = 1.15
	p.volume_db = BOSS_PEAK_VOLUME_DB
	if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
		p.bus = GameManager.ensure_labyrinth_echo_bus()
	add_child(p)
	return p

func _setup_boss_complementary_audio() -> void:
	_boss_audio_1 = _load_boss_audio_stream("res://Assets/Music/audio boss 1")
	_boss_audio_2 = _load_boss_audio_stream("res://Assets/Music/audio boss 2")

	_boss_voice_player_a = _create_boss_voice_player("BossVoicePlayerA")
	_boss_voice_player_b = _create_boss_voice_player("BossVoicePlayerB")

func _start_boss_voice_cycle() -> void:
	if not _boss_voice_player_a or not _boss_voice_player_b or not is_active or current_state == State.DEAD:
		return
	if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
		var echo_bus: StringName = GameManager.ensure_labyrinth_echo_bus()
		_boss_voice_player_a.bus = echo_bus
		_boss_voice_player_b.bus = echo_bus

	_boss_voice_player_a.stop()
	_boss_voice_player_b.stop()
	_is_crossfading_boss_audio = false
	_crossfade_elapsed = 0.0
	_active_boss_slot = 0

	if _boss_audio_1:
		_boss_voice_player_a.stream = _boss_audio_1
		_boss_voice_player_a.volume_db = BOSS_PEAK_VOLUME_DB
		_boss_voice_player_a.pitch_scale = 1.0
		_boss_voice_player_a.play()
	elif _boss_audio_2:
		_active_boss_slot = 1
		_boss_voice_player_b.stream = _boss_audio_2
		_boss_voice_player_b.volume_db = BOSS_PEAK_VOLUME_DB
		_boss_voice_player_b.pitch_scale = 1.0
		_boss_voice_player_b.play()

func _update_boss_voice_crossfade(delta: float) -> void:
	if not is_active or current_state == State.DEAD:
		return
	if not _boss_voice_player_a or not _boss_voice_player_b:
		return
	if not _boss_audio_1 and not _boss_audio_2:
		return

	var cur_player: AudioStreamPlayer2D = _boss_voice_player_a if _active_boss_slot == 0 else _boss_voice_player_b
	var next_player: AudioStreamPlayer2D = _boss_voice_player_b if _active_boss_slot == 0 else _boss_voice_player_a
	var next_stream: AudioStream = _boss_audio_2 if _active_boss_slot == 0 else _boss_audio_1
	if not next_stream:
		next_stream = _boss_audio_1 if _boss_audio_1 else _boss_audio_2

	if not _is_crossfading_boss_audio:
		if not cur_player.playing:
			# Fallback restart if stream ended before crossfade window
			_begin_boss_crossfade(cur_player, next_player, next_stream, 0.35)
			return
		var stream_len := cur_player.stream.get_length() if cur_player.stream else 0.0
		var cur_pos := cur_player.get_playback_position()
		var remaining := stream_len - cur_pos
		var fade_window := clampf(stream_len * 0.26, 0.65, BOSS_CROSSFADE_TIME) if stream_len > 0.0 else BOSS_CROSSFADE_TIME
		if stream_len > 0.0 and remaining <= fade_window:
			_begin_boss_crossfade(cur_player, next_player, next_stream, maxf(0.35, remaining))
	else:
		_crossfade_elapsed += delta
		var t := clampf(_crossfade_elapsed / maxf(0.05, _crossfade_duration), 0.0, 1.0)
		# Equal-power crossfade curve so the two audios fuse smoothly at full terror level without any volume dip
		var out_gain := cos(t * PI * 0.5)
		var in_gain := sin(t * PI * 0.5)
		var peak_lin := db_to_linear(BOSS_PEAK_VOLUME_DB)
		cur_player.volume_db = linear_to_db(maxf(0.001, out_gain * peak_lin))
		next_player.volume_db = linear_to_db(maxf(0.001, in_gain * peak_lin))

		if t >= 1.0:
			cur_player.stop()
			next_player.volume_db = BOSS_PEAK_VOLUME_DB
			_active_boss_slot = 1 - _active_boss_slot
			_is_crossfading_boss_audio = false
			_crossfade_elapsed = 0.0

func _begin_boss_crossfade(cur_player: AudioStreamPlayer2D, next_player: AudioStreamPlayer2D, next_stream: AudioStream, duration: float) -> void:
	if not next_stream:
		return
	_is_crossfading_boss_audio = true
	_crossfade_elapsed = 0.0
	_crossfade_duration = maxf(0.30, duration)
	next_player.stream = next_stream
	next_player.pitch_scale = randf_range(0.98, 1.02)
	next_player.volume_db = -24.0
	next_player.play()
	if not cur_player.playing:
		cur_player.volume_db = -40.0

func _stop_all_boss_voices() -> void:
	_is_crossfading_boss_audio = false
	if _boss_voice_player_a and _boss_voice_player_a.playing:
		_boss_voice_player_a.stop()
	if _boss_voice_player_b and _boss_voice_player_b.playing:
		_boss_voice_player_b.stop()

func _deactivate_boss() -> void:
	is_active = false
	visible = false
	attack_timer.stop()
	_stop_all_boss_voices()
	$CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)

func activate_boss() -> void:
	if is_active:
		return
	is_active = true
	visible = true
	current_health = max_health
	current_state = State.IDLE
	$CollisionShape2D.set_deferred("disabled", false)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", false)
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)
	if anim_player.has_animation("idle"):
		anim_player.play("idle")
	attack_timer.start(randf_range(1.1, 1.8))
	_start_boss_voice_cycle()

func _process(delta: float) -> void:
	if not is_active or current_state == State.DEAD:
		return
	_update_boss_voice_crossfade(delta)
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player_ref):
		_track_player_with_eyes(delta)
	_update_nervous_head_tic(delta)

func _physics_process(delta: float) -> void:
	if not is_active or current_state == State.DEAD:
		return
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		return
	if player_ref.get("is_reading_intro") or player_ref.get("is_dead"):
		velocity = Vector2.ZERO
		return

	var to_player := player_ref.global_position - global_position
	var dist := to_player.length()
	var dir_to_player := to_player.normalized() if dist > 1.0 else Vector2.DOWN

	# Aim AttackHitbox toward the player so the manotazo hits in the player's direction
	if attack_hitbox_shape:
		attack_hitbox_shape.position = dir_to_player * 115.0 + Vector2(0, -25)
		attack_hitbox_shape.rotation = dir_to_player.angle() + PI * 0.5

	if _knockback_velocity.length() > 12.0:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 950.0 * delta)

	if current_state == State.IDLE:
		var spd := chase_speed * (1.24 if current_health < max_health * 0.5 else 1.0)
		if dist > 180.0:
			velocity = dir_to_player * spd + _knockback_velocity
		else:
			velocity = _knockback_velocity
			# Trigger immediate manotazo when close to the player
			if attack_timer.time_left > 0.25:
				_start_boss_attack()

		_walk_bob_time += delta * 6.5
		if visuals:
			visuals.position = _base_visuals_pos + Vector2(0.0, sin(_walk_bob_time) * 7.0)
			visuals.rotation = sin(_walk_bob_time * 0.5) * 0.04
	elif current_state == State.ATTACKING:
		_update_attack_motion(delta, dir_to_player)
		velocity = _lunge_velocity + _knockback_velocity
		# Check overlapping bodies while AttackHitbox is active
		if attack_hitbox_shape and not attack_hitbox_shape.disabled:
			for b in attack_hitbox.get_overlapping_bodies():
				_on_hitbox_body_entered(b)

	move_and_slide()

	# Contact damage if the Boss body slams directly into the player during a lunge
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage)

func _update_nervous_head_tic(delta: float) -> void:
	if not head_sprite:
		return

	var enraged_mult := 1.55 if (current_health < max_health * 0.5 or current_state == State.ATTACKING) else 1.0
	_tic_timer -= delta * enraged_mult

	if _tic_timer <= 0.0:
		# Trigger a sharp nervous tic spasm on the Boss's head
		_tic_spasm_time = randf_range(0.10, 0.22)
		_tic_timer = randf_range(0.22, 0.68)
		var side := -1.0 if randf() < 0.5 else 1.0
		_tic_target_rot = side * randf_range(0.16, 0.34)
		_tic_target_offset = Vector2(side * randf_range(6.0, 14.0), randf_range(-8.0, 6.0))

	if _tic_spasm_time > 0.0:
		_tic_spasm_time -= delta
		# Rapid involuntary double-jerk during spasm
		var flicker := sin(_tic_spasm_time * 95.0)
		_tic_current_rot = lerpf(_tic_current_rot, _tic_target_rot * signf(flicker + 0.25), delta * 38.0)
		_tic_current_offset = _tic_current_offset.lerp(_tic_target_offset * signf(flicker + 0.25), delta * 38.0)
	else:
		# Snap back toward neutral with subtle constant nervous micro-tremor
		var micro_rot := randf_range(-0.025, 0.025)
		var micro_pos := Vector2(randf_range(-1.8, 1.8), randf_range(-1.5, 1.5))
		_tic_current_rot = lerpf(_tic_current_rot, micro_rot, delta * 22.0)
		_tic_current_offset = _tic_current_offset.lerp(micro_pos, delta * 22.0)

	head_sprite.position = _base_head_pos + _tic_current_offset
	head_sprite.rotation = _tic_current_rot
	if eye_socket:
		eye_socket.position = _base_eye_socket_pos + _tic_current_offset
		eye_socket.rotation = _tic_current_rot

func _track_player_with_eyes(delta: float) -> void:
	var dir_to_player = player_ref.global_position - eye_socket.global_position
	var target_offset = dir_to_player.limit_length(eye_max_distance)
	eyes_sprite.position = eyes_sprite.position.lerp(target_offset, eye_follow_speed * delta)

func _on_attack_timer_timeout() -> void:
	if not is_active or current_state != State.IDLE:
		return
	_start_boss_attack()

func _start_boss_attack() -> void:
	if not is_active or current_state != State.IDLE:
		return
	current_state = State.ATTACKING
	_slash_triggered_in_anim = false
	_second_slash_triggered = false
	_lunge_velocity = Vector2.ZERO

	# Force an immediate head tic spasm as a creepy telegraph before slapping
	_tic_timer = 0.0

	var chosen_anim: String = "3rd_leg_attack"
	if current_health < max_health * 0.65 and randf() < 0.5:
		chosen_anim = "double_manotazo"
	elif randf() < 0.35:
		chosen_anim = "double_manotazo"

	anim_player.play(chosen_anim)

func _update_attack_motion(delta: float, dir_to_player: Vector2) -> void:
	if not anim_player.is_playing():
		return
	var pos := anim_player.current_animation_position
	var anim := anim_player.current_animation

	if anim == "3rd_leg_attack":
		if pos < 0.38:
			# Windup: Boss pulls back slightly and raises arm
			_lunge_velocity = -dir_to_player * 95.0
			if visuals:
				visuals.rotation = lerpf(visuals.rotation, -0.14, delta * 12.0)
				visuals.scale = visuals.scale.lerp(Vector2(1.08, 0.94), delta * 12.0)
		elif pos >= 0.38 and pos < 0.68:
			# Strike (Manotazo!): Boss lunges hard toward the player and slams claw down
			if not _slash_triggered_in_anim:
				_slash_triggered_in_anim = true
				_lunge_velocity = dir_to_player * 640.0
				_spawn_claw_slash_effect(dir_to_player)
				_play_manotazo_sfx()
			_lunge_velocity = _lunge_velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
			if visuals:
				visuals.rotation = lerpf(visuals.rotation, 0.16, delta * 22.0)
				visuals.scale = visuals.scale.lerp(Vector2(0.94, 1.10), delta * 22.0)
		else:
			_lunge_velocity = _lunge_velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
			if visuals:
				visuals.rotation = lerpf(visuals.rotation, 0.0, delta * 12.0)
				visuals.scale = visuals.scale.lerp(Vector2.ONE, delta * 12.0)
	elif anim == "double_manotazo":
		if pos >= 0.32 and pos < 0.56 and not _slash_triggered_in_anim:
			_slash_triggered_in_anim = true
			_lunge_velocity = dir_to_player * 600.0
			_spawn_claw_slash_effect(dir_to_player)
			_play_manotazo_sfx()
		elif pos >= 0.86 and pos < 1.10 and not _second_slash_triggered:
			_second_slash_triggered = true
			_lunge_velocity = dir_to_player * 680.0
			_spawn_claw_slash_effect(dir_to_player)
			_play_manotazo_sfx()
		else:
			_lunge_velocity = _lunge_velocity.move_toward(Vector2.ZERO, 1300.0 * delta)

func _spawn_claw_slash_effect(dir: Vector2) -> void:
	var slash := Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(-15, -95),
		Vector2(45, -65),
		Vector2(80, 0),
		Vector2(45, 65),
		Vector2(-15, 95),
		Vector2(28, 0)
	])
	slash.color = Color(0.85, 0.12, 0.16, 0.85)
	slash.position = dir * 115.0 + Vector2(0, -25)
	slash.rotation = dir.angle()
	slash.z_index = 15
	add_child(slash)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(slash, "scale", Vector2(1.45, 1.35), 0.18)
	tw.tween_property(slash, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(slash.queue_free)

func _play_manotazo_sfx() -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.volume_db = -3.0
	if get_node_or_null("/root/GameManager") and GameManager.has_method("ensure_labyrinth_echo_bus"):
		sfx.bus = GameManager.ensure_labyrinth_echo_bus()
	add_child(sfx)
	var mix_rate := 22050
	var duration := 0.18
	var total_samples := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	var lp := 0.0
	for i in range(total_samples):
		var t := float(i) / float(mix_rate)
		var env := sin(minf(1.0, t / 0.03) * PI * 0.5) * exp(-t * 20.0)
		var raw := randf() * 2.0 - 1.0
		lp += 0.12 * (raw - lp)
		var swipe := lp * 0.45 + sin(TAU * (165.0 - t * 420.0) * t) * 0.72
		var s_val := int(clampf(swipe * env, -1.0, 1.0) * 24000.0)
		bytes.encode_s16(i * 2, s_val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	sfx.stream = wav
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _on_animation_finished(_anim_name: StringName) -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE
		_lunge_velocity = Vector2.ZERO
		if attack_hitbox_shape:
			attack_hitbox_shape.set_deferred("disabled", true)
		if visuals:
			visuals.rotation = 0.0
			visuals.scale = Vector2.ONE
		if anim_player.has_animation("idle"):
			anim_player.play("idle")
		var next_wait := randf_range(0.65, 1.25) if current_health < max_health * 0.5 else randf_range(0.95, 1.65)
		attack_timer.start(next_wait)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

func apply_knockback(force: Vector2) -> void:
	_knockback_velocity = force * 0.35

func take_damage(amount: int) -> void:
	if not is_active or current_state == State.DEAD:
		return

	current_health -= amount
	print("Boss took damage! Remaining HP: ", current_health, "/", max_health)
	_flash_sprites()
	# Trigger a violent head tic when hit
	_tic_timer = 0.0

	if current_health <= 0:
		_die()

func _flash_sprites() -> void:
	var tween = create_tween()
	visuals.modulate = Color(2.2, 0.25, 0.25, 1.0)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.14)

	var particles := CPUParticles2D.new()
	particles.position = Vector2(0, -45)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 18
	particles.lifetime = 0.38
	particles.explosiveness = 0.92
	particles.spread = 180.0
	particles.gravity = Vector2(0, 260)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 220.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 11.0
	particles.color = Color(0.62, 0.05, 0.08, 0.94)
	add_child(particles)
	get_tree().create_timer(0.45).timeout.connect(particles.queue_free)

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	_lunge_velocity = Vector2.ZERO
	attack_timer.stop()
	_stop_all_boss_voices()
	anim_player.stop(true)
	$CollisionShape2D.set_deferred("disabled", true)
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(eyes_sprite, "position", Vector2.ZERO, 0.25)
	tween.tween_property(visuals, "modulate", Color(0.35, 0.05, 0.05, 0.0), 0.75)
	tween.tween_property(visuals, "scale", Vector2(0.85, 0.72), 0.75)

	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player_ref) and player_ref.has_method("show_final_boss_victory_flashback"):
		player_ref.show_final_boss_victory_flashback()
