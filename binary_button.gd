class_name BinaryButton
extends Button

var binary_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(path: String) -> void:
	self.binary_path = path
	
	self.text = self.binary_path.get_file()
	
	self.pressed.connect(func() -> void:
		var err := OS.create_process(binary_path, ["-p"])
		if err < 0:
			OS.alert("Unable to start binary at path %s" % binary_path)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
