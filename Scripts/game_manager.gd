extends Node

var kill_count: int = 0
var cicle: int = 0
var current_phase: int = 1
var is_genocide_route: bool = false
var collected_wall_notes: Dictionary = {}
var intro_notes_shown: bool = false

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

func advance_to_phase_two() -> void:
	current_phase = 2
	cicle = maxi(cicle + 1, 1)
	print("Advanced to Phase 2 | Route: ", get_route_name(), " | Kills: ", kill_count)

func reset_kills() -> void:
	if current_phase == 1:
		kill_count = 0
		is_genocide_route = false
		collected_wall_notes.clear()

func next_cicle() -> void:
	cicle += 1
	print("Cicle: ", cicle)