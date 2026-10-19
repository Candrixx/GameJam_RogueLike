extends EnemyBase

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Phase 1 shadow enemies: slow enough so the protagonist can evade them without killing them
	fov_degrees = 360.0
	view_distance = 760.0
	patrol_speed = 65.0
	chase_speed = 185.0
	patrol_radius = 110.0
	wait_chance = 0.5
	super()

func _on_player_spotted() -> void:
	pass
