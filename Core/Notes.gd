extends Control

@onready var notes_graph: GraphEdit = $NotesGraph
@onready var add_button: Button = $UI/AddNoteButton

var text_note_scene = preload("res://Core/UIElements/TextNoteNode.tscn")
var image_note_scene = preload("res://Core/UIElements/ImageNoteNode.tscn")
var note_counter = 0

func _ready():
	pass
	## Connect signals
	#add_button.pressed.connect(_on_add_note_button_pressed)
	#notes_graph.files_dropped_on_graph.connect(_on_notes_files_dropped)
	#
	## Enable file dropping - corrected method call with proper callable references
	#notes_graph.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)
	#
	## Set up clipboard monitoring for paste functionality
	#set_process_input(true)

func _input(event):
	# Handle Ctrl+V for pasting
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_V:
			_handle_paste()

func _handle_paste():
	# Try to get clipboard content
	var clipboard_text = DisplayServer.clipboard_get()
	
	if clipboard_text != "":
		# Check if it's an image path or URL
		if _is_image_path(clipboard_text):
			_create_image_note(clipboard_text)
		else:
			# Create text note with clipboard content
			_create_text_note(clipboard_text)

func _is_image_path(path: String) -> bool:
	var extensions = [".png", ".jpg", ".jpeg", ".bmp", ".tga", ".webp"]
	var lower_path = path.to_lower()
	
	for ext in extensions:
		if lower_path.ends_with(ext):
			return true
	return false

func _on_add_note_button_pressed():
	_create_text_note("")

func _on_notes_files_dropped(files: PackedStringArray, position: Vector2):
	for file_path in files:
		if _is_image_path(file_path):
			_create_image_note(file_path, position)
		else:
			# Try to read as text file
			_create_text_note_from_file(file_path, position)

func _create_text_note(initial_text: String = "", pos: Vector2 = Vector2.ZERO):
	var note_node = text_note_scene.instantiate()
	note_counter += 1
	
	note_node.name = "TextNote_" + str(note_counter)
	note_node.title = "Note " + str(note_counter)
	note_node.position_offset = pos if pos != Vector2.ZERO else _get_random_position()
	
	notes_graph.add_child(note_node)
	
	# Set initial text if provided
	if initial_text != "":
		note_node.set_text(initial_text)

func _create_text_note_from_file(file_path: String, pos: Vector2 = Vector2.ZERO):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		_create_text_note(content, pos)
	else:
		print("Could not read file: ", file_path)

func _create_image_note(image_path: String, pos: Vector2 = Vector2.ZERO):
	var note_node = image_note_scene.instantiate()
	note_counter += 1
	
	note_node.name = "ImageNote_" + str(note_counter)
	note_node.title = "Image " + str(note_counter)
	note_node.position_offset = pos if pos != Vector2.ZERO else _get_random_position()
	
	notes_graph.add_child(note_node)
	
	# Load and set the image
	note_node.set_image(image_path)

func _get_random_position() -> Vector2:
	var graph_size = notes_graph.size
	var random_x = randf_range(50, graph_size.x - 250)
	var random_y = randf_range(50, graph_size.y - 150)
	return Vector2(random_x, random_y)

func _can_drop_data(position: Vector2, data) -> bool:
	# Allow dropping of files
	return data.has("files") or data.has("text")

func _drop_data(position: Vector2, data):
	if data.has("files"):
		_on_notes_files_dropped(data["files"], position)
	elif data.has("text"):
		_create_text_note(data["text"], position)
