class_name Config
extends Resource

const SAVE_PATH := "user://config.tres"

@export
var first_time_setup := true
@export
var default_search_path: String = ""
@export
var close_on_run := false
@export
var registered_binaries: Array[String] = []

func save() -> int:
	return ResourceSaver.save(self, SAVE_PATH)

func reset() -> void:
	first_time_setup = true
	default_search_path = ""
	registered_binaries.clear()
