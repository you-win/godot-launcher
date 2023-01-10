extends CanvasLayer

const ConfigEdit: PackedScene = preload("res://config_edit.tscn")

@onready
var add_binary_button: Button = %AddBinary
@onready
var verify_button: Button = %Verify
@onready
var edit_config_button: Button = %EditConfig
@onready
var config_dir_button: Button = %ConfigDir
@onready
var binaries: VBoxContainer = %Binaries

var user_home_path := ""
var config: Config = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	config = load(Config.SAVE_PATH) if FileAccess.file_exists(Config.SAVE_PATH) else Config.new()
	
	if not config.default_search_path.is_empty():
		user_home_path = config.default_search_path
	elif config.first_time_setup:
		config.first_time_setup = false
		user_home_path = _get_home_dir()

func _ready() -> void:
	add_binary_button.pressed.connect(func() -> void:
		var popup := FileSelector.new(user_home_path, FileDialog.FILE_MODE_OPEN_FILE)
		popup.file_selected.connect(func(path: String) -> void:
			if _register_binary(path):
				_add_binary(path)
			if popup.is_queued_for_deletion():
				return
			popup.queue_free()
		)
		
		add_child(popup)
		popup.popup_centered_ratio()
	)
	verify_button.pressed.connect(func() -> void:
		if _all_binaries_exist():
			OS.alert("All binaries verified to exist!", "Woo!")
		else:
			get_tree().reload_current_scene()
	)
	edit_config_button.pressed.connect(func() -> void:
		var popup: Window = ConfigEdit.instantiate()
		popup.config = config
		popup.close_requested.connect(func() -> void:
			if popup.is_queued_for_deletion():
				return
			popup.queue_free()
			get_tree().reload_current_scene()
		)
		
		add_child(popup)
		popup.popup_centered_ratio()
	)
	config_dir_button.pressed.connect(func() -> void:
		OS.shell_open(OS.get_user_data_dir())
	)
	
	_all_binaries_exist()
	for path in config.registered_binaries:
		_add_binary(path)

func _exit_tree() -> void:
	ResourceSaver.save(config, Config.SAVE_PATH)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _get_home_dir() -> String:
	var err: int = -1
	var output: Array[String] = []
	match OS.get_name().to_lower():
		"windows":
			err = OS.execute("cmd.exe", ["/C", "echo %USERPROFILE%"], output)
		"linux", "macos":
			err = OS.execute("/bin/bash", ["-c", "echo $HOME"])
		_:
			OS.alert("Unsupported OS %s. This still might work." % OS.get_name())
			return ""
	
	if err < 0 or output.is_empty():
		OS.alert("Failed to read user home directory.")
	
	return output.back().strip_edges()

func _queue_free(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	node.queue_free()

func _add_binary(path: String) -> void:
	var button := BinaryButton.new(path)
	button.pressed.connect(func() -> void:
		if config.close_on_run:
			get_tree().quit()
	)
	binaries.add_child(button)

func _register_binary(path: String) -> bool:
	if config.registered_binaries.has(path):
		return false
	
	config.registered_binaries.append(path)
	var err := config.save()
	if err != OK:
		printerr("Failed to save config: %d" % err)
		return false
	
	return true

func _all_binaries_exist() -> bool:
	var missing_binaries: Array[String] = []
	for path in config.registered_binaries:
		if not FileAccess.file_exists(path):
			missing_binaries.append(path)
	
	var missing_list := ""
	for path in missing_binaries:
		missing_list += "%s " % path
		config.registered_binaries.erase(path)
	
	missing_list = missing_list.strip_edges()
	
	if not missing_binaries.is_empty():
		OS.alert("The following binaries could not be found: %s" % missing_list, "Spoopy!")
	
	return missing_list.is_empty()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
