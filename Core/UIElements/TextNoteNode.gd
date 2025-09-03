# TextNoteNode.gd - Create this as a new script file
extends GraphNode

var text_edit: TextEdit
var node_id: int

func setup_node(id: int, initial_text: String = ""):
	node_id = id
	name = "TextNote_" + str(id)
	#title = "Text Note " + str(id)
	
	
	# Set up the GraphNode
	resizable = true
	size = Vector2(300, 200)
	
	# Create TextEdit
	text_edit = TextEdit.new()
	text_edit.size = Vector2(280, 150)
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.placeholder_text = "Enter your note here..."
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.text = initial_text
	
	# Add TextEdit to the node
	add_child(text_edit)
	
	# Connect signals for auto-resize
	text_edit.text_changed.connect(_on_text_changed)

func _on_text_changed():
	# Optional: Auto-resize based on content
	var line_count = text_edit.get_line_count()
	var new_height = max(150, line_count * 20 + 50)
	size.y = new_height + 50  # Add some padding for the title

func get_note_text() -> String:
	return text_edit.text if text_edit else ""

func set_note_text(text: String):
	if text_edit:
		text_edit.text = text

func _on_close_button_pressed() -> void:
	queue_free()
