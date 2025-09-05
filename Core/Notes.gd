# NotesGraph.gd - Attach this to your GraphEdit node
extends GraphEdit

@onready var add_button: Button
var node_counter = 0
var notes_folder = "notes"
var notes_file = AssetLoader.get_base_path() + "notes/notes.json"
var saved_images = {}  # Track which images we've already saved

func _ready():
	# Set up the GraphEdit
	name = "Notes"
	
	# Create notes directory if it doesn't exist
	_ensure_notes_directory()
	
	# Load existing notes
	_load_notes()
	
	# Create and add the + button
	add_button = Button.new()
	add_button.text = "+"
	add_button.size = Vector2(30, 30)
	add_button.position = Vector2(10, 10)
	add_button.pressed.connect(_on_add_button_pressed)
	add_child(add_button)
	
	# Enable drag and drop
	set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	
	# Connect deletion signal (but don't auto-save)
	delete_nodes_request.connect(_on_delete_nodes_request)

# Call this function when the application is closing
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_quit_request()

func _ensure_notes_directory():
	if not DirAccess.dir_exists_absolute(AssetLoader.get_base_path() + notes_folder):
		DirAccess.open(AssetLoader.get_base_path()).make_dir_recursive(notes_folder)

func _get_drag_data(position: Vector2):
	return null

func _can_drop_data(position: Vector2, data) -> bool:
	if data.has("files") or data.has("text"):
		return true
	return false

func _drop_data(position: Vector2, data):
	if data.has("files"):
		for file_path in data.files:
			if _is_image_file(file_path):
				_create_image_node(position, file_path)
			else:
				_create_text_node(position, "File: " + file_path.get_file())
	elif data.has("text"):
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
	var clipboard_image = DisplayServer.clipboard_get_image()
	if clipboard_image:
		var center_pos = scroll_offset + size / 2
		_create_image_node_from_image(center_pos, clipboard_image)
	else:
		var clipboard_text = DisplayServer.clipboard_get()
		if clipboard_text != "":
			var center_pos = scroll_offset + size / 2
			_create_text_node(center_pos, clipboard_text)

func _on_add_button_pressed():
	var pos = Vector2(100 + node_counter * 50, 100 + node_counter * 50)
	_create_text_node(pos, "New Note")

func _create_text_node(pos: Vector2, text: String):
	var text_node = preload("res://Core/UIElements/TextNoteNode.tscn").instantiate()
	text_node.setup_node(node_counter, text)
	text_node.position_offset = pos
	add_child(text_node)
	node_counter += 1

func _create_image_node(pos: Vector2, image_path: String):
	var image_node = preload("res://Core/UIElements/ImageNoteNode.tscn").instantiate()
	image_node.setup_node(node_counter, image_path)
	image_node.position_offset = pos
	add_child(image_node)
	node_counter += 1

func _create_image_node_from_image(pos: Vector2, image: Image, title_text: String = "Image"):
	var image_node = preload("res://Core/UIElements/ImageNoteNode.tscn").instantiate()
	image_node.setup_node_from_image(node_counter, image, title_text)
	image_node.position_offset = pos
	add_child(image_node)
	node_counter += 1

func _on_delete_nodes_request(nodes: Array):
	for node_name in nodes:
		var node = get_node(NodePath(node_name))
		if node:
			# If it's an image node, delete the associated image file
			if node.name.begins_with("ImageNote_") and node.has_method("get_image_data"):
				_delete_image_file(node.node_id)
			node.queue_free()

func _delete_image_file(node_id: int):
	var filename = "image_" + str(node_id) + ".png"
	var file_path = notes_folder + "/" + filename
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(notes_folder)
		if dir:
			var error = dir.remove(filename)
			if error == OK:
				print("Deleted image file: ", file_path)
			else:
				print("Failed to delete image file: ", file_path, " Error: ", error)
		else:
			print("Could not access notes directory for deletion")
	
	# Remove from saved images tracking
	if saved_images.has(node_id):
		saved_images.erase(node_id)

func _on_quit_request():
	print("App closing, saving notes...")
	_save_notes()
	#get_tree().quit()

func _save_notes():
	var notes_data = {
		"node_counter": node_counter,
		"notes": []
	}
	
	# Clear the saved images tracking for this save
	saved_images.clear()
	
	# Get all note nodes
	for child in get_children():
		if child.name.begins_with("TextNote_") or child.name.begins_with("ImageNote_"):
			var note_data = {
				"type": "",
				"id": 0,
				"position": {"x": 0, "y": 0},
				"title": "",
				"size": {"x": 0, "y": 0}
			}
			
			note_data.id = child.node_id if child.has_method("get") and "node_id" in child else 0
			note_data.position = {"x": child.position_offset.x, "y": child.position_offset.y}
			note_data.title = child.title
			note_data.size = {"x": child.size.x, "y": child.size.y}
			
			if child.name.begins_with("TextNote_"):
				note_data.type = "text"
				note_data.content = child.get_text() if child.has_method("get_text") else ""
			elif child.name.begins_with("ImageNote_"):
				note_data.type = "image"
				var filename = "image_" + str(child.node_id) + ".png"
				var dest_path = notes_folder + "/" + filename
				
				# Only save the image if we haven't saved it yet in this session
				if not saved_images.has(child.node_id):
					if child.has_method("get_image_path") and child.get_image_path() != "":
						# Image from file - load and save as PNG to avoid format issues
						var original_image = Image.new()
						if original_image.load(child.get_image_path()) == OK:
							original_image.save_png(dest_path)
							saved_images[child.node_id] = true
							print("Saved image from file: ", dest_path)
					elif child.has_method("get_image_data") and child.get_image_data() != null:
						# Image from clipboard - save as PNG
						child.get_image_data().save_png(dest_path)
						saved_images[child.node_id] = true
						print("Saved image from clipboard: ", dest_path)
				
				note_data.image_file = filename
			
			notes_data.notes.append(note_data)
	
	# Save current scroll position and zoom
	notes_data.scroll_offset = {"x": scroll_offset.x, "y": scroll_offset.y}
	notes_data.zoom = zoom
	
	# Save JSON file
	var json_string = JSON.stringify(notes_data, "\t")
	var file = FileAccess.open(notes_file, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Notes saved to ", notes_file)
	else:
		print("Failed to save notes file")

func _load_notes():
	if not FileAccess.file_exists(notes_file):
		print("No existing notes file found")
		return
	
	var file = FileAccess.open(notes_file, FileAccess.READ)
	if not file:
		print("Failed to open notes file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse notes JSON")
		return
	
	var notes_data = json.data
	
	# Restore node counter
	if notes_data.has("node_counter"):
		node_counter = notes_data.node_counter
	
	if notes_data.has("scroll_offset") and notes_data.has("zoom"):
		# Apply scroll and zoom after all nodes are loaded
		# Use call_deferred to ensure the GraphEdit has processed all the new nodes
		call_deferred("_apply_saved_view_state", Vector2(notes_data.scroll_offset.x, notes_data.scroll_offset.y), notes_data.zoom)
	
	# Restore notes
	if notes_data.has("notes"):
		for note_data in notes_data.notes:
			var pos = Vector2(note_data.position.x, note_data.position.y)
			
			if note_data.type == "text":
				var text_node = preload("res://Core/UIElements/TextNoteNode.tscn").instantiate()
				text_node.setup_node(note_data.id, note_data.content)
				text_node.position_offset = pos
				text_node.size = Vector2(note_data.size.x, note_data.size.y)
				text_node.title = note_data.title
				add_child(text_node)
			
			elif note_data.type == "image" and note_data.has("image_file"):
				var image_path = notes_folder + "/" + note_data.image_file
				if FileAccess.file_exists(image_path):
					var image_node = preload("res://Core/UIElements/ImageNoteNode.tscn").instantiate()
					image_node.setup_node(note_data.id, image_path)
					image_node.position_offset = pos
					image_node.size = Vector2(note_data.size.x, note_data.size.y)
					image_node.title = note_data.title
					add_child(image_node)
					
					# Mark this image as already saved to prevent overwriting
					saved_images[note_data.id] = true
				else:
					print("Image file not found: ", image_path)
	
	print("Notes loaded from ", notes_file)

func _apply_saved_view_state(offset_to_set, zoom_to_set):
	scroll_offset = offset_to_set
	zoom = zoom_to_set
