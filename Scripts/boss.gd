extends CharacterBody2D

enum State {IDLE, ATTACKING, DEAD } # añadir luego

@export var max_health: int = 1
@export var damage: int = 2

@export var eye_max_distance: float = 6.0 
@export var eye_follow_speed: float = 12.0

var current_health: int
var current_state: State = State.IDLE
var player_ref: Node2D = null

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var eye_socket: Marker2D = $Visuals/EyeSocket
@onready var eyes_sprite: Sprite2D = $Visuals/EyeSocket/EyesSprite
@onready var attack_hitbox: Area2D = $AttackHitbox

const ATTACKS = [
	"3rd_leg_attack"
]

func _ready() -> void:
	self.visible = false
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("player")
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	anim_player.animation_finished.connect(_on_animation_finished)
	attack_hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	#anim_player.play("idle") no hay idle por el momento
	attack_timer.start(randf_range(1.5, 3))

func _process(delta: float) -> void:
	if current_state != State.DEAD and is_instance_valid(player_ref):
		_track_player_with_eyes(delta)

func _track_player_with_eyes(delta: float) -> void:
	# Vector global desde el centro de la cuenca hacia el jugador
	var dir_to_player = player_ref.global_position - eye_socket.global_position
	
	# Calculamos el objetivo local limitándolo al radio máximo
	var target_offset = dir_to_player.limit_length(eye_max_distance)
	
	eyes_sprite.position = eyes_sprite.position.lerp(target_offset, eye_follow_speed * delta)

func _on_attack_timer_timeout() -> void:
	if current_state != State.IDLE:
		return
		
	current_state = State.ATTACKING
	anim_player.play(ATTACKS.pick_random())

func _on_animation_finished(anim_name: StringName) -> void:
	if current_state == State.ATTACKING:
		current_state = State.IDLE
		anim_player.stop(true)
		attack_timer.start(randf_range(1.0, 2.0))

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
		
	current_health -= amount
	_flash_sprites()
	
	if current_health <= 0:
		_die()

func _flash_sprites() -> void:
	var tween = create_tween()
	$Visuals.modulate = Color.RED
	tween.tween_property($Visuals, "modulate", Color.WHITE, 0.15)

func _die() -> void:
	current_state = State.DEAD
	attack_timer.stop()
	
	# Al morir, devuelve los ojos al centro o cerrarlos
	var tween = create_tween()
	tween.tween_property(eyes_sprite, "position", Vector2.ZERO, 0.2)
	
	anim_player.stop(true) # Hay que crear una animacion de muerte
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
