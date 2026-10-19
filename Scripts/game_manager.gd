extends Node

var kill_count: int = 0
var cicle: int = 0

func add_kill() -> void:
	kill_count += 1
	print("Kills: ", kill_count)

func reset_kills() -> void:
	kill_count = 0

func next_cicle() -> void:
	var root = get_tree().current_scene

	var layer_name: String = "cicle" + str(cicle)

	print(layer_name)

	var layer = root.get_node_or_null(layer_name)

	if layer:
		layer.process_mode = Node.PROCESS_MODE_DISABLED
		layer.visible = false
		layer.collision_enabled = false
		layer.occlusion_enabled = false

	cicle += 1
	print("Cicle: ", cicle)

	layer_name = "cicle" + str(cicle)

	print(layer_name)

	var new_layer = root.get_node_or_null(layer_name)

	if new_layer:
		new_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		new_layer.visible = true
		new_layer.collision_enabled = true
		new_layer.occlusion_enabled = true