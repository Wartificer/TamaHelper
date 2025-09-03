extends GraphNode

@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
var is_editing = false

func _ready():
	# Set up the node properties
	resizable = true
	size = Vector2(250, 150)
	
	# Connect signals
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.focus_entered.connect(_on_focus_entered)
	text_edit.focus_exited.connect(_on_focus_exited)
	
	## Set up close button
	#show_close = true
	#close_request.connect(_on_close_request)
	
	# Configure text edit
	text_edit.placeholder_text = "Enter your note..."
	#text_edit.wrap_mode = TextEdit.LINE_WRAPPING_WORD_SMART
	text_edit.scroll_fit_content_height = true

func set_text(text: String):
	text_edit.text = text
	_update_title()

func get_text() -> String:
	return text_edit.text

func _on_text_changed():
	_update_title()

func _update_title():
	var text = text_edit.text.strip_edges()
	if text.length() > 0:
		# Use first line as title, truncate if too long
		var first_line = text.split("\n")[0]
		if first_line.length() > 20:
			title = first_line.substr(0, 17) + "..."
		else:
			title = first_line
	else:
		title = "Empty Note"

func _on_focus_entered():
	is_editing = true

func _on_focus_exited():
	is_editing = false

func _on_close_request():
	queue_free()

# Save/Load functionality for future use
func get_note_data() -> Dictionary:
	return {
		"type": "text",
		"position": position_offset,
		"size": size,
		"title": title,
		"text": text_edit.text
	}

func load_note_data(data: Dictionary):
	position_offset = data.get("position", Vector2.ZERO)
	size = data.get("size", Vector2(250, 150))
	title = data.get("title", "Note")
	text_edit.text = data.get("text", "")
