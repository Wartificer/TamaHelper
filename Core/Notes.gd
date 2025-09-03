extends Control

@onready var add_button = $UI/AddButton
@onready var notes_container = $NotesContainer
@onready var notes_viewport = $NotesContainer
@onready var notes_content = $NotesContainer/NotesContent

# The element you want to scale
@export var target_element: Control
# Scale limits
const MIN_SCALE = 0.2
const MAX_SCALE = 1.0
# Scale increment per wheel step
const SCALE_STEP = 0.1

# Preload the note item scene
var note_item_scene = preload("res://Core/UIElements/NoteItem.tscn")

func _ready():
	add_button.pressed.connect(_on_add_button_pressed)
	
	# Enable drag and drop
	set_process_input(true)
	
	# Make sure this node can receive input even when not focused
	set_process_unhandled_input(true)

func _on_add_button_pressed():
	create_text_note()

func create_text_note():
	var note_item = note_item_scene.instantiate()
	notes_content.add_child(note_item)
	
	# Position new note at a random location
	var rand_pos = Vector2(
		randf_range(50, 500),
		randf_range(50, 500)
	)
	note_item.position = rand_pos
	note_item.setup_as_text()

func create_image_note(image_path: String):
	var note_item = note_item_scene.instantiate()
	notes_content.add_child(note_item)
	
	var rand_pos = Vector2(
		randf_range(50, 500),
		randf_range(50, 500)
	)
	note_item.position = rand_pos
	note_item.setup_as_image(image_path)

# Handle file drops
func _can_drop_data(position, data):
	return data.has("files")

func _drop_data(position, data):
	if data.has("files"):
		for file_path in data["files"]:
			if file_path.get_extension().to_lower() in ["png", "jpg", "jpeg", "bmp", "webp"]:
				create_image_note(file_path)

func _unhandled_input(event):
	# Only process if current_tab is "notes"
	if Utils.current_tab != "Notes":
		return
	
	# Check for mouse wheel events
	if event is InputEventMouseButton:
		# Check if CTRL is pressed
		if event.ctrl_pressed:
			print("A")
			var new_scale = target_element.scale.x
			
			# Scroll up (wheel up) - increase scale
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_scale = min(new_scale + SCALE_STEP, MAX_SCALE)
				apply_scale(new_scale)
				# Mark event as handled so it doesn't propagate
				get_viewport().set_input_as_handled()
			
			# Scroll down (wheel down) - decrease scale
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_scale = max(new_scale - SCALE_STEP, MIN_SCALE)
				apply_scale(new_scale)
				# Mark event as handled so it doesn't propagate
				get_viewport().set_input_as_handled()

func apply_scale(scale_value: float):
	if target_element:
		# Apply uniform scaling to both x and y
		target_element.scale = Vector2(scale_value, scale_value)
