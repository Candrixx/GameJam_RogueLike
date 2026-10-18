class_name Character
extends CharacterBody2D

@export var speed = 100
@export var accelaration = 10
@onready var area_hitbox: Area2D = $Area2D
var weapon_equiped: ArmaBase = null
@onready var point_equipment: Marker2D = $EquimentPoint

func _physics_process(delta: float) -> void:
	var attack = Input.is_action_just_pressed("attack")
	if attack and weapon_equiped:
		weapon_equiped.attack()
	
	
	var direction := Input.get_vector("left", "right", "up", "down")
	velocity = velocity.lerp(speed * direction, delta * accelaration)
	
	move_and_slide()


func equip_weapon(new_weapon: PackedScene):
	if weapon_equiped:
		weapon_equiped.queue_free()
		
	weapon_equiped = new_weapon.instantiate() as ArmaBase
	if weapon_equiped:
		point_equipment.add_child(weapon_equiped)
		weapon_equiped.position = Vector2.ZERO
		weapon_equiped.rotation = 0
	
