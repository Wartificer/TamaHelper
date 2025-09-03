extends GraphNode

@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
var image_path: String = ""

func _ready():
	# Set up the node properties
	resizable = true
	size = Vector2(300, 200)
	
	## Set up close button
	#show_close = true
	#close_request.connect(_on_close_request)
	
	# Configure texture rect
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(200, 150)

func set_image(path: String):
	image_path = path
	_load_image()

func _load_image():
	var texture: Texture2D
	
	# Check if it's a local file path or URL
	if image_path.begins_with("http"):
		# For web images, you'd need to implement HTTP request
		# For now, just show placeholder
		print("Web images not implemented yet: ", image_path)
		_set_placeholder_text("Web Image\n(Not supported)")
		return
	
	# Try to load as local file
	if FileAccess.file_exists(image_path):
		var image = Image.new()
		var error = image.load(image_path)
		
		if error == OK:
			texture = ImageTexture.new()
			texture.set_image(image)
			texture_rect.texture = texture
			
			# Update title with filename
			var filename = image_path.get_file()
			title = filename.get_basename()
			
			# Resize node to fit image better
			_resize_to_fit_image(image.get_size())
		else:
			print("Error loading image: ", error)
			_set_placeholder_text("Failed to\nload image")
	else:
		print("Image file not found: ", image_path)
		_set_placeholder_text("Image not\nfound")

func _set_placeholder_text(text: String):
	# Create a simple colored rectangle as placeholder
	var placeholder = ColorRect.new()
	placeholder.color = Color(0.3, 0.3, 0.3, 1.0)
	placeholder.custom_minimum_size = Vector2(200, 150)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	
	placeholder.add_child(label)
	
	# Replace texture_rect with placeholder
	texture_rect.get_parent().remove_child(texture_rect)
	texture_rect.get_parent().add_child(placeholder)
	texture_rect = placeholder

func _resize_to_fit_image(image_size: Vector2):
	var max_width = 400
	var max_height = 300
	var padding = Vector2(20, 40) # Account for node chrome
	
	var scale_x = max_width / image_size.x
	var scale_y = max_height / image_size.y
	var scale = min(scale_x, scale_y)
	
	if scale < 1.0:
		var new_size = image_size * scale + padding
		size = new_size
		texture_rect.custom_minimum_size = image_size * scale
	else:
		size = image_size + padding
		texture_rect.custom_minimum_size = image_size

func _on_close_request():
	queue_free()

# Save/Load functionality for future use
func get_note_data() -> Dictionary:
	return {
		"type": "image",
		"position": position_offset,
		"size": size,
		"title": title,
		"image_path": image_path
	}
