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

const MUSIC_TENSA_CALMA := "res://Assets/Music/Tensa Calma.mp3"
const MUSIC_PELIGRO_3 := "res://Assets/Music/Peligro 3.mp3"
const MUSIC_PELIGRO := "res://Assets/Music/Peligro.mp3"
const MUSIC_CAMINO_BUENO := "res://Assets/Music/Camino Bueno.mp3"

var phase_two_note_found: bool = false
var open_credits_on_menu: bool = false
var _current_music_path: String = ""

func _ready() -> void:
	ensure_labyrinth_echo_bus()
	play_music(MUSIC_TENSA_CALMA)

func play_music(track_path: String, force_restart: bool = false) -> void:
	if not ResourceLoader.exists(track_path):
		return
	var bg_node := get_node_or_null("/root/BgMusic")
	if not bg_node:
		return
	bg_node.process_mode = Node.PROCESS_MODE_ALWAYS
	if not force_restart and _current_music_path == track_path and bg_node.get("playing") == true:
		return
	var stream := load(track_path) as AudioStream
	if not stream:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_current_music_path = track_path
	bg_node.set("volume_db", -2.5 if track_path == MUSIC_PELIGRO else 0.0)
	bg_node.set("stream", stream)
	bg_node.call("play")

func ensure_labyrinth_echo_bus() -> StringName:
	var bus_name := &"LabyrinthEcho"
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"Master")

		# 1. Noise removal stage (cuts low-frequency mic hum/rumble and high-frequency hiss/static while keeping full mid-range voice presence)
		var hpf := AudioEffectHighPassFilter.new()
		hpf.cutoff_hz = 85.0
		hpf.resonance = 0.5
		hpf.db = AudioEffectFilter.FILTER_12DB
		AudioServer.add_bus_effect(idx, hpf)

		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 4800.0
		lpf.resonance = 0.5
		lpf.db = AudioEffectFilter.FILTER_12DB
		AudioServer.add_bus_effect(idx, lpf)

		var eq := AudioEffectEQ10.new()
		eq.set_band_gain_db(0, -24.0) # 31 Hz hum
		eq.set_band_gain_db(1, -14.0) # 62 Hz hum
		eq.set_band_gain_db(4, 2.5)   # 500 Hz body boost
		eq.set_band_gain_db(5, 3.0)   # 1000 Hz presence boost
		eq.set_band_gain_db(6, 2.5)   # 2000 Hz clarity boost
		eq.set_band_gain_db(8, -16.0) # 8000 Hz hiss
		eq.set_band_gain_db(9, -24.0) # 16000 Hz static
		AudioServer.add_bus_effect(idx, eq)

		# 2. Labyrinth Echo stage (Delay + Reverb)
		var delay_fx := AudioEffectDelay.new()
		delay_fx.tap1_active = true
		delay_fx.tap1_delay_ms = 215.0
		delay_fx.tap1_level_db = -8.5
		delay_fx.tap1_pan = -0.25
		delay_fx.tap2_active = true
		delay_fx.tap2_delay_ms = 430.0
		delay_fx.tap2_level_db = -13.5
		delay_fx.tap2_pan = 0.25
		delay_fx.feedback_active = true
		delay_fx.feedback_delay_ms = 240.0
		delay_fx.feedback_level_db = -11.5
		delay_fx.feedback_lowpass = 2800.0
		AudioServer.add_bus_effect(idx, delay_fx)

		var reverb_fx := AudioEffectReverb.new()
		reverb_fx.room_size = 0.72
		reverb_fx.damping = 0.52
		reverb_fx.spread = 0.85
		reverb_fx.wet = 0.28
		reverb_fx.dry = 0.90
		AudioServer.add_bus_effect(idx, reverb_fx)
	return bus_name

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

func advance_to_phase_three() -> void:
	current_phase = 3
	cicle = maxi(cicle + 1, 2)
	phase_two_note_found = true
	print("Advanced to Phase 3 (Boss Room) | Route: ", get_route_name(), " | Kills: ", kill_count)

func reset_to_phase_one() -> void:
	current_phase = 1
	cicle = 0
	kill_count = 0
	is_genocide_route = false
	collected_wall_notes.clear()
	collected_item_ids.clear()
	saved_inventory = null
	saved_selected_slot = 0
	phase_two_note_found = false
	print("Reset to Phase 1 from 0")

func reset_kills() -> void:
	reset_to_phase_one()

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
