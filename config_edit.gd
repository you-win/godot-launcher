extends Window

class DraggableLabel extends HBoxContainer:
	var label := Label.new()
	var button := Button.new()
	
	var text := "" :
		set(new_text):
			label.text = new_text
		get:
			return label.text
	
	func _init(path: String) -> void:
		label.text = path
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.mouse_default_cursor_shape = Control.CURSOR_DRAG
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		add_child(label)
		
		button.text = "Delete"
		button.pressed.connect(func() -> void:
			self.queue_free()
		)
		
		add_child(button)
	
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is DraggableLabel
	
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		var from_label: DraggableLabel = data
		var old_text := self.text
		
		self.text = from_label.label.text
		from_label.text = old_text
	
	func _get_drag_data(_at_position: Vector2) -> Variant:
		var preview := DraggableLabel.new(self.text)
		preview.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		set_drag_preview(preview)
		return self

@onready
var default_search_path: LineEdit = %DefaultSearchPath
@onready
var picker: Button = %Picker
@onready
var close_on_run: CheckButton = %CloseOnRun
@onready
var binaries: VBoxContainer = %Binaries
@onready
var reset_config: Button = %ResetConfig

const ResetConfigSteps := {
	"START": "Reset",
	"CONFIRM": "Confirm?",
	"COMPLETE": "Reset complete!",
	"ERROR": "Error, check the logs."
}

var config: Config = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	default_search_path.text = config.default_search_path
	default_search_path.tooltip_text = "The default path to use when selecting a binary."
	
	picker.pressed.connect(func() -> void:
		var popup := FileSelector.new(default_search_path.text, FileDialog.FILE_MODE_OPEN_DIR)
		popup.dir_selected.connect(func(path: String) -> void:
			default_search_path.text = path
			if popup.is_queued_for_deletion():
				return
			popup.queue_free()
		)
		add_child(popup)
		popup.popup_centered_ratio()
	)
	
	close_on_run.set_pressed_no_signal(config.close_on_run)
	
	for binary in config.registered_binaries:
		binaries.add_child(DraggableLabel.new(binary))
	
	reset_config.text = ResetConfigSteps.START
	reset_config.pressed.connect(func() -> void:
		match reset_config.text:
			ResetConfigSteps.START:
				reset_config.text = ResetConfigSteps.CONFIRM
			ResetConfigSteps.CONFIRM:
				config.reset()
				if config.save() == OK:
					reset_config.text = ResetConfigSteps.COMPLETE
				else:
					reset_config.text = ResetConfigSteps.ERROR
	)
	reset_config.mouse_exited.connect(func() -> void:
		reset_config.text = ResetConfigSteps.START
	)
	reset_config.tooltip_text = "Completely reset the current config with a confirmation step."

func _exit_tree() -> void:
	config.default_search_path = default_search_path.text
	config.close_on_run = close_on_run.button_pressed
	config.registered_binaries.clear()
	for label in binaries.get_children():
		config.registered_binaries.append(label.text)
	
	if config.save() != OK:
		printerr("Failed to save config while closing edit window")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
