class_name BinaryButton
extends Button

signal order_changed()

var binary_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(path: String) -> void:
	self.binary_path = path
	self.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	self.text = self.binary_path.get_file()
	
	self.pressed.connect(func() -> void:
		var err := OS.create_process(binary_path, ["-p"])
		if err < 0:
			OS.alert("Unable to start binary at path %s" % binary_path)
	)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is BinaryButton
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from: BinaryButton = data
	var old_text := self.text
	var old_binary_path := self.binary_path
	
	self.text = from.text
	self.binary_path = from.binary_path
	
	from.text = old_text
	from.binary_path = old_binary_path
	
	order_changed.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = self.text
	set_drag_preview(preview)
	return self

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
