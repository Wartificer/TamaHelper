# ImageNoteNode.gd - Create this as a new script file
extends GraphNode

var texture_rect: TextureRect
var node_id: int
var image_path: String

func setup_node(id: int, img_path: String):
	node_id = id
	image_path = img_path
	name = "ImageNote_" + str(id)
	#title = "Image Note " + str(id)
	
	# Set up the GraphNode
	resizable = true
	
	# Create TextureRect for displaying the image
	texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load and set the image
	var image = Image.new()
	var error = image.load(img_path)
	
	if error == OK:
		var texture = ImageTexture.new()
		texture.create_from_image(image)
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
	else:
		# If image loading fails, show an error message
		var label = Label.new()
		label.text = "Failed to load image:\n" + img_path.get_file()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(label)
		size = Vector2(200, 100)
		return
	
	add_child(texture_rect)

func get_image_path() -> String:
	return image_path

func _on_close_request():
	queue_free()
