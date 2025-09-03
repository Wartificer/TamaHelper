# ImageNoteNode.gd - Create this as a new script file
extends GraphNode

var texture_rect: TextureRect
var node_id: int
var image_path: String
var image_data: Image  # Store the actual image data

func setup_node(id: int, img_path: String):
	node_id = id
	image_path = img_path
	name = "ImageNote_" + str(id)
	#title = "Image Note " + str(id)
	
	# Set up the GraphNode
	resizable = true
	
	# Load image from path
	var image = Image.new()
	var error = image.load(img_path)
	
	if error == OK:
		image_data = image
		_setup_texture_rect_with_image(image)
	else:
		_show_error_message("Failed to load image:\n" + img_path.get_file())

func setup_node_from_image(id: int, image: Image, title_text: String = "Image"):
	node_id = id
	image_path = ""  # No file path since we're using direct image data
	image_data = image
	name = "ImageNote_" + str(id)
	#title = title_text + " " + str(id)
	
	# Set up the GraphNode
	resizable = true
	
	# Use the provided image directly
	_setup_texture_rect_with_image(image)

func _setup_texture_rect_with_image(image: Image):
	# Create TextureRect for displaying the image
	texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.set_image(image)
	texture_rect.texture = texture
	
	# Calculate appropriate size
	var img_size = texture.get_size()
	var max_width = 400
	var max_height = 300
	
	var scale_factor = min(max_width / img_size.x, max_height / img_size.y)
	scale_factor = min(scale_factor, 1.0)  # Don't scale up
	
	var display_size = img_size * scale_factor
	texture_rect.size = display_size
	size = display_size + Vector2(20, 50)  # Add padding for title and border
	
	add_child(texture_rect)

func _show_error_message(message: String):
	# If image loading fails, show an error message
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	size = Vector2(200, 100)

func get_image_path() -> String:
	return image_path

func get_image_data() -> Image:
	return image_data

func has_image_data() -> bool:
	return image_data != null

func _on_close_button_pressed() -> void:
	queue_free()
