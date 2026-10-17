class_name Character
extends CharacterBody2D

@export var speed = 100
@export var accelaration = 10
@onready var animation_attack: AnimationPlayer = $AnimationPlayer
@onready var area_hitbox: Area2D = $Area2D

func _physics_process(delta: float) -> void:
	var attack = Input.is_action_just_pressed("attack")
	if attack:
		attack_animation()
	
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("right"):
		direction.x = 1
	elif Input.is_action_pressed("left"):
		direction.x = -1
	
	if direction.x == 0:
		if Input.is_action_pressed("down"):
			direction.y = 1
		elif Input.is_action_pressed("up"):
			direction.y = -1
	
	velocity = velocity.lerp(speed * direction, delta * accelaration)
	
	move_and_slide()

func attack_animation():
	if animation_attack.is_playing() and animation_attack.current_animation == "Atque":
		return
	
	animation_attack.play("Atque")

func _on_area_2d_body_entered(body):
	print("Hubo contacto")

func take_weapon(name, damage, frame_number):
	pass
