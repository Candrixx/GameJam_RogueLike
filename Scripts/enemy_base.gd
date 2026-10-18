class_name EnemyBase

extends CharacterBody2D

enum State { PATROL, WAIT, CHASE, SEARCH }

# Variables de vision
@export var fov_degrees: float = 190.0
@export var view_distance: float = 300.0
@export var player_group: StringName = &"player"

# Variables de movimiento
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 180.0
@export var acceleration: float = 350.0
@export var patrol_radius: float = 80.0
@export var search_timeout: float = 4.0
@export var lost_sight_grace: float = 3

# Variables de knockback
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 800.0

# Vida del enemigo
@export var life = 999
var is_dead = false

# Pausas de espera
@export var wait_chance: float = 0.5
@export var wait_min: float = 1.0
@export var wait_max: float = 3.0
@export var wait_spin_speed: float = 2.0

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

func _ready() -> void:
	_patrol_origin = global_position
	_pick_patrol_target()
	animated_sprite = find_child("*AnimatedSprite2D*", true, false) as AnimatedSprite2D

	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_player = get_tree().get_first_node_in_group(player_group)
	var sees_player := _player != null and can_see_player(_player)

	if knockback_velocity.length() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
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

# Vision

func can_see_player(player: Node2D) -> bool:
	var eyes_pos := global_position
	var target_pos := player.global_position
	var dir_to_player := eyes_pos.direction_to(target_pos)

	if eyes_pos.distance_to(target_pos) > view_distance:
		return false

	var half_fov_cos := cos(deg_to_rad(fov_degrees / 2.0))
	if facing_dir.dot(dir_to_player) < half_fov_cos:
		return false

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(eyes_pos, target_pos)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)

	if not result:
		return false

	var hit = result.collider
	while hit:
		if hit == player:
			return true
		hit = hit.get_parent()
	return false

# Estados

func _enter_chase() -> void:
	state = State.CHASE
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
	if global_position.distance_to(_patrol_target) < 12.0:
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
		_search_spin += delta * 4.0
		_facing_from_angle(_search_spin)

# Movimiento

func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(patrol_radius * 0.3, patrol_radius)
	_patrol_target = _patrol_origin + Vector2(cos(angle), sin(angle)) * dist

func _move_toward_point(target: Vector2, speed: float, delta: float) -> void:
	var dir := (target - global_position)
	if dir.length() < 1.0:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		return

	dir = dir.normalized()
	velocity = velocity.move_toward(dir * speed, acceleration * delta)
	_facing_from_vector(dir)

# Knockback

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

# Daño

func take_damage(damage: int) -> void:
	if is_dead:
		return

	life -= damage
	print(self.name, " remaining life: ", life)

	if life <= 0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	var collider = find_child("*CollisionShape2D*", true, false) as CollisionShape2D
	if collider:
		collider.set_deferred("disabled", true)

	if animated_sprite:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.35)

		await tween.finished

# Facing

func _facing_from_vector(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		facing_dir = Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	else:
		facing_dir = Vector2.DOWN if v.y > 0.0 else Vector2.UP

	_update_enemy_sprite()

func _update_enemy_sprite() -> void:
	if not animated_sprite:
		return

	if facing_dir == Vector2.DOWN:
		animated_sprite.play("walk_down")
	elif facing_dir == Vector2.UP:
		animated_sprite.play("walk_up")
	# elif facing_dir == Vector2.LEFT:
	# 	animated_sprite.play("walk_left")
	# elif facing_dir == Vector2.RIGHT:
	# 	animated_sprite.play("walk_right")

func _facing_from_angle(a: float) -> void:
	_facing_from_vector(Vector2(cos(a), sin(a)))
