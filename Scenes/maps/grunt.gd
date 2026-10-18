extends EnemyBase

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Per-type defaults (still overridable per instance in the Inspector)
	fov_degrees = 180.0
	view_distance = 800.0
	patrol_speed = 40.0
	chase_speed = 400.0
	patrol_radius = 60.0
	wait_chance = 0.7
	super()   # llama base _ready para inicializar el origen de la patrulla

func _on_player_spotted() -> void:
	# en caso de necesitar
	pass
	
