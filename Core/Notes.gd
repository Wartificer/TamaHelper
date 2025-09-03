# NotesGraph.gd - Attach this to your GraphEdit node
extends GraphEdit

@onready var add_button: Button
var node_counter = 0

func _ready():
	# Set up the GraphEdit
	name = "Notes"
	
	# Create and add the + button
	add_button = Button.new()
	add_button.text = "+"
	add_button.size = Vector2(30, 30)
	add_button.position = Vector2(10, 10)
	add_button.pressed.connect(_on_add_button_pressed)
	add_child(add_button)
	
	# Enable drag and drop
	set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	
	# Connect deletion signal
	delete_nodes_request.connect(_on_delete_nodes_request)

func _get_drag_data(position: Vector2):
	# We don't need to handle dragging from the GraphEdit itself
	# Return null to use default behavior
	return null

func _can_drop_data(position: Vector2, data) -> bool:
	# Accept files and text
	if data.has("files") or data.has("text"):
		return true
	return false

func _drop_data(position: Vector2, data):
	if data.has("files"):
		# Handle file drops (images)
		for file_path in data.files:
			if _is_image_file(file_path):
				_create_image_node(position, file_path)
			else:
				# For non-image files, create a text node with the file name
				_create_text_node(position, "File: " + file_path.get_file())
	elif data.has("text"):
		# Handle text drops
		_create_text_node(position, data.text)

func _is_image_file(file_path: String) -> bool:
	var extensions = [".png", ".jpg", ".jpeg", ".bmp", ".webp", ".svg"]
	var lower_path = file_path.to_lower()
	for ext in extensions:
		if lower_path.ends_with(ext):
			return true
	return false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_V:
			_handle_paste()

func _handle_paste():
	var clipboard_text = DisplayServer.clipboard_get()
	if clipboard_text != "":
		# Create text node at center of view
		var center_pos = scroll_offset + size / 2
		_create_text_node(center_pos, clipboard_text)

func _on_add_button_pressed():
	# Create a new text node at a default position
	var pos = Vector2(100 + node_counter * 50, 100 + node_counter * 50)
	_create_text_node(pos, "New Note")

func _create_text_node(pos: Vector2, text: String):
	var text_node = preload("res://Core/UIElements/TextNoteNode.gd").new()
	text_node.setup_node(node_counter, text)
	text_node.position_offset = pos
	add_child(text_node)
	node_counter += 1

func _create_image_node(pos: Vector2, image_path: String):
	var image_node = preload("res://Core/UIElements/ImageNoteNode.gd").new()
	image_node.setup_node(node_counter, image_path)
	image_node.position_offset = pos
	add_child(image_node)
	node_counter += 1

func _on_delete_nodes_request(nodes: Array):
	for node_name in nodes:
		var node = get_node(NodePath(node_name))
		if node:
			node.queue_free()
