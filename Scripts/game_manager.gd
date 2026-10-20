extends Node

var kill_count: int = 0
var cicle: int = 0
var current_phase: int = 1
var is_genocide_route: bool = false
var collected_wall_notes: Dictionary = {}
var intro_notes_shown: bool = false

var saved_inventory = null
var saved_selected_slot: int = 0
var collected_item_ids: Array = []

var phase_two_note_found: bool = false

func add_kill() -> void:
	kill_count += 1
	is_genocide_route = true
	print("Kills: ", kill_count, " | Route: GENOCIDE")

func is_pacifist_route() -> bool:
	return not is_genocide_route and kill_count == 0

func get_route_name() -> String:
	return "genocide" if is_genocide_route or kill_count > 0 else "pacifist"

func mark_wall_note_collected(note_id: String) -> void:
	collected_wall_notes[note_id] = true

func is_wall_note_collected(note_id: String) -> bool:
	return collected_wall_notes.has(note_id)

func unlock_phase_two_barrier() -> void:
	phase_two_note_found = true
	print("Phase 2 note found! Upper-right barrier opened.")

func advance_to_phase_two() -> void:
	current_phase = 2
	cicle = maxi(cicle + 1, 1)
	phase_two_note_found = false
	print("Advanced to Phase 2 | Route: ", get_route_name(), " | Kills: ", kill_count)

func reset_kills() -> void:
	if current_phase == 1:
		kill_count = 0
		is_genocide_route = false
		collected_wall_notes.clear()
	elif current_phase == 2:
		# If restarting phase 2 on death, reset phase 2 note if needed
		pass

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
