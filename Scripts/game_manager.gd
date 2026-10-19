extends Node

var kill_count: int = 0
var cicle: int = 0

func add_kill() -> void:
	kill_count += 1
	print("Kills: ", kill_count)

func reset_kills() -> void:
	kill_count = 0

func next_cicle() -> void:
	cicle += 1
	print("Cicle: ", cicle)