extends ScrollContainer

var is_dragging = false
var drag_start_pos = Vector2()
var scroll_start_pos = Vector2()
var drag_threshold = 10.0
var drag_speed_multiplier = 1.5  # Speed multiplier for dragging
var buttons_connected = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Connect to buttons after the scene is ready
	call_deferred("connect_all_buttons")

func connect_all_buttons():
	if buttons_connected:
		return
	buttons_connected = true
	connect_buttons_recursive(self)

func connect_buttons_recursive(node: Node):
	for child in node.get_children():
		if child is BaseButton:  # This catches Button, CheckBox, etc.
			# Connect to the button's gui_input signal
			if not child.gui_input.is_connected(_on_button_gui_input):
				child.gui_input.connect(_on_button_gui_input.bind(child))
		else:
			connect_buttons_recursive(child)

func _on_button_gui_input(event: InputEvent, button: BaseButton):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Store initial click position
			drag_start_pos = event.global_position
			scroll_start_pos = Vector2(scroll_horizontal, scroll_vertical)
			is_dragging = false
		else:
			# Mouse released - RESET everything
			if is_dragging:
				# If we were dragging, don't let the button handle the release
				get_viewport().set_input_as_handled()
			is_dragging = false
			drag_start_pos = Vector2()  # Reset the drag start position
	
	elif event is InputEventMouseMotion and drag_start_pos != Vector2():
		var distance = drag_start_pos.distance_to(event.global_position)
		
		# Start dragging if moved beyond threshold
		if distance > drag_threshold and not is_dragging:
			is_dragging = true
			# Release the button's pressed state
			button.button_pressed = false
		
		# If dragging, scroll and consume the event
		if is_dragging:
			var drag_delta = event.global_position - drag_start_pos
			# Apply speed multiplier to make scrolling faster
			scroll_horizontal = scroll_start_pos.x - (drag_delta.x * drag_speed_multiplier)
			scroll_vertical = scroll_start_pos.y - (drag_delta.y * drag_speed_multiplier)
			get_viewport().set_input_as_handled()

# Also handle regular ScrollContainer input for areas without buttons
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = false
			drag_start_pos = event.global_position
			scroll_start_pos = Vector2(scroll_horizontal, scroll_vertical)
		else:
			is_dragging = false
			drag_start_pos = Vector2()  # Reset here too
	
	elif event is InputEventMouseMotion and drag_start_pos != Vector2():
		var distance = drag_start_pos.distance_to(event.global_position)
		if distance > drag_threshold:
			is_dragging = true
		
		if is_dragging:
			var drag_delta = event.global_position - drag_start_pos
			# Apply speed multiplier to make scrolling faster
			scroll_horizontal = scroll_start_pos.x - (drag_delta.x * drag_speed_multiplier)
			scroll_vertical = scroll_start_pos.y - (drag_delta.y * drag_speed_multiplier)
