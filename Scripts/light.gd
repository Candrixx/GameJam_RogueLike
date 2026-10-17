extends Node2D

@export var energy_multiplier: float = 1.0:
	set(value):
		energy_multiplier = value
		if is_node_ready():
			_update_lights()

var _base_energies: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is PointLight2D:
			_base_energies[child] = child.energy
	_update_lights()

func _update_lights() -> void:
	for light in _base_energies:
		light.energy = _base_energies[light] * energy_multiplier
