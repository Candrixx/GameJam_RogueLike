class_name Character
extends CharacterBody2D

@export var speed = 500
@export var accelaration = 50


var weapon_equiped: ArmaBase = null
var last_direction = Vector2.DOWN

@onready var area_hitbox: Area2D = $Area2D
@onready var point_equipment: Marker2D = $EquipmentPoint
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var attack = Input.is_action_just_pressed("attack")
	if attack and weapon_equiped:
		weapon_equiped.attack()
	
	
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

func equip_weapon(new_weapon: PackedScene):
	if weapon_equiped:
		weapon_equiped.queue_free()
		
	weapon_equiped = new_weapon.instantiate() as ArmaBase
	if weapon_equiped:
		point_equipment.add_child(weapon_equiped)
		weapon_equiped.position = Vector2.ZERO
		weapon_equiped.rotation = 0
	
