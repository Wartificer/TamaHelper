extends Control

@onready var background = $Background
@onready var top_bar = $TopBar
@onready var top_bar_bg = $TopBar/TopBarBG
@onready var close_button = $TopBar/CloseButton
@onready var content_container = $ContentContainer
@onready var text_edit = $ContentContainer/TextEdit
@onready var image_display = $ContentContainer/ImageDisplay

var dragging = false
var drag_offset = Vector2.ZERO
var is_text_note = true

func _ready():
	# Setup sizes and positions
	custom_minimum_size = Vector2(200, 150)
	size = Vector2(200, 150)
	
	# Setup background
	background.size = size
	background.color = Color(0.2, 0.2, 0.2, 0.9)
	
	# Setup top bar
	top_bar.size = Vector2(size.x, 30)
	
	# Setup close button
	close_button.text = "×"
	close_button.size = Vector2(30, 30)
	close_button.position = Vector2(size.x - 30, 0)
	close_button.pressed.connect(_on_close_pressed)
	
	# Setup content container
	content_container.position = Vector2(5, 35)
	content_container.size = Vector2(size.x - 10, size.y - 40)
	
	# Setup text edit
	text_edit.size = content_container.size
	text_edit.placeholder_text = "Type your note here..."
	#text_edit.wrap_mode = TextEdit.LINE_WRAPPING_WORD_SMART
	
	# Setup image display
	image_display.size = content_container.size
	image_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Connect input events
	top_bar.gui_input.connect(_on_top_bar_input)

func setup_as_text():
	is_text_note = true
	text_edit.visible = true
	image_display.visible = false
	text_edit.grab_focus()

func setup_as_image(image_path: String):
	is_text_note = false
	text_edit.visible = false
	image_display.visible = true
	
	# Load and display image
	var image = Image.new()
	var error = image.load(image_path)
	if error == OK:
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		image_display.texture = texture

func _on_top_bar_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = event.position
				# Bring to front
				get_parent().move_child(self, -1)
			else:
				dragging = false
	
	elif event is InputEventMouseMotion and dragging:
		position += event.position - drag_offset

func _on_close_pressed():
	queue_free()

# Handle resizing
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if clicking near bottom-right corner for resizing
			var corner_size = 20
			var bottom_right = size - Vector2(corner_size, corner_size)
			if event.position.x >= bottom_right.x and event.position.y >= bottom_right.y:
				# Start resize (you can implement this if needed)
				pass
