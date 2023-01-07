extends CanvasLayer

@onready
var add_binary_button: Button = %AddBinary
@onready
var config_dir_button: Button = %ConfigDir
@onready
var binaries: VBoxContainer = %Binaries

var user_home_path := ""
var config: Config

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	var err: int = -1
	var output: Array[String] = []
	match OS.get_name().to_lower():
		"windows":
			err = OS.execute("cmd.exe", ["/C", "echo %USERPROFILE%"], output)
		"linux", "macos":
			err = OS.execute("/bin/bash", ["-c", "echo $HOME"])
		_:
			OS.alert("Unsupported OS %s. This still might work." % OS.get_name())
			return
	
	if err < 0 or output.is_empty():
		OS.alert("Failed to read user home directory.")
	
	user_home_path = output.back().strip_edges()
	
	config = load(Config.SAVE_PATH) if FileAccess.file_exists(Config.SAVE_PATH) else Config.new()

func _ready() -> void:
	add_binary_button.pressed.connect(func() -> void:
		var popup := FileDialog.new()
		popup.access = FileDialog.ACCESS_FILESYSTEM
		popup.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		popup.current_dir = user_home_path
		popup.close_requested.connect(_queue_free.bind(popup))
		popup.cancelled.connect(_queue_free.bind(popup))
		popup.confirmed.connect(_queue_free.bind(popup))
		popup.file_selected.connect(func(path: String) -> void:
			if _register_binary(path):
				_add_binary(path)
			_queue_free(popup)
		)
		
		add_child(popup)
		popup.popup_centered_ratio()
	)
	config_dir_button.pressed.connect(func() -> void:
		OS.shell_open(OS.get_user_data_dir())
	)
	for path in config.registered_binaries:
		_add_binary(path)

func _exit_tree() -> void:
	ResourceSaver.save(config, Config.SAVE_PATH)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _queue_free(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	node.queue_free()

func _add_binary(path: String) -> void:
	var button := BinaryButton.new(path)
	binaries.add_child(button)

func _register_binary(path: String) -> bool:
	if config.registered_binaries.has(path):
		return false
	
	config.registered_binaries.append(path)
	ResourceSaver.save(config, Config.SAVE_PATH)
	
	return true

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
