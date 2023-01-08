class_name FileSelector
extends FileDialog

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(path: String, file_mode: FileMode) -> void:
	self.access = FileDialog.ACCESS_FILESYSTEM
	self.file_mode = file_mode
	self.current_dir = path
	self.close_requested.connect(_queue_free.bind(self))
	self.cancelled.connect(_queue_free.bind(self))
	self.confirmed.connect(_queue_free.bind(self))

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _queue_free(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	node.queue_free()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

