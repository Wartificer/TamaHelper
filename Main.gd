extends Control

const SETTINGS_FILE = "user://settings.cfg"

## Timer
@onready var TIMER : Timer = %CaptureTimer
## Information Container
@onready var INFO_CONTAINER : VBoxContainer = %InfoContainer
## Tamanimation player
@onready var TAMANIMATION_PLAYER : AnimationPlayer = %TamanimationPlayer

## Screen size
var screen_size : Vector2
## How many screens are there
var screen_count : int = DisplayServer.get_screen_count()  # total monitors
## Current screen being checked
var current_screen : int = 1
## If the program keep_alives every 1 second
var keep_alive : bool
## If the app should always be visible.
var always_on_top : bool
## Disables Tamamo Animations if true
var disable_anims : bool

## Resulting text from a previous capture process
var previous_texts_result : Array[String]

## All data linking event text and their images
var character_data : Variant
var support_data : Variant

## Current career character
var selected_character : Dictionary


func load_json_data(path : String):
	var file = FileAccess.open("res://" + path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			return json.data
		else:
			print("Error parsing JSON: ", json.get_error_message())
	else:
		print("Error opening file")
	return {}

var character_button_scene = load("res://CharacterButton.tscn")
func load_character_list():
	for character in character_data:
		var character_button = character_button_scene.instantiate()
		character_button.get_child(0).texture = load("res://CharacterData/" + character.preview)
		character_button.pressed.connect(on_character_selected.bind(character))
		%CharacterList.add_child(character_button)

## Initialize OCR Manager
func _ready():
	get_screen_size()
	character_data = load_json_data("CharacterData/data.json")
	support_data = load_json_data("SupportData/data.json")
	load_character_list()
	load_settings()
	# Connect to OCR signals
	OCRManager.ocr_completed.connect(_on_ocr_completed)
	OCRManager.ocr_failed.connect(_on_ocr_failed)

func get_screen_size():
	screen_size = DisplayServer.screen_get_size(current_screen)

func _on_ocr_completed(text: String):
	print("OCR Success! Extracted text: ", text)

func _on_ocr_failed(error: String):
	print("OCR Failed: ", error)


func capture_screen():
	# Grab the screen image for the current monitor
	var img: Image = DisplayServer.screen_get_image(current_screen)
	if img == null:
		return  # failed to capture

	# Convert the Image to a Texture for display
	var tex = ImageTexture.create_from_image(img)
	%ImagePreview.texture = tex
	process_capture(img)

## Starts the program by capturing the screen
func _on_start_button_pressed() -> void:
	get_screen_size()
	capture_screen()
	if keep_alive:
		if %StartButton.text == "Stop":
			%StartButton.text = "Start"
			%CaptureTimer.stop()
		else:
			%StartButton.text = "Stop"
			TIMER.start()
	else:
		%StartButton.set_pressed_no_signal(false)

## When timer finishes, capture again
func _on_capture_timer_timeout() -> void:
	capture_screen()
	if keep_alive:
		TIMER.start()

## Sets if the program keep_alives or executes only once
func _on_auto_toggle_toggled(toggled_on: bool) -> void:
	keep_alive = toggled_on
	save_settings()

func _on_always_on_top_toggle_toggled(toggled_on: bool) -> void:
	always_on_top = toggled_on
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	save_settings()

## Switches to check a different screen
func _on_switch_screen_button_pressed() -> void:
	current_screen = (current_screen + 1) % screen_count
	get_screen_size()
	%CurrentScreenLabel.text = str(current_screen + 1)
	save_settings()

func _on_disable_anims_toggled(toggled_on: bool) -> void:
	disable_anims = toggled_on
	save_settings()


var item_image_scene = load("res://ItemImage.tscn")
var event_image_scene = load("res://EventImage.tscn")
func process_capture(capture : Image):
	var result = ImageReader.check_matching_pixels(screen_size, capture)
	# If there was no match, stop
	if result == {}:
		return
	
	print("MATCHING: " + result.label)
	
	## If there is something matching on screen, get the text inside the designated areas
	var texts_result : Array[String] = await ImageReader.get_image_texts(screen_size, result, capture)
	## If the text is the same as previous text shown, stop process
	if texts_result == previous_texts_result:
		return
	
	previous_texts_result = texts_result
	if texts_result.size() > 0:
		# Clear previous info
		for child in INFO_CONTAINER.get_children():
			child.queue_free()
			
		# Add information to screen
		for text in texts_result:
			var found
			# Find text in character data
			found = find_text_in_data([selected_character], "res://CharacterData/", text)
			# Find text in supports instead
			if !found:
				found = find_text_in_data(support_data, "res://SupportData/", text)
				
			# If an event was found for text, present it
			if found:
				show_event_info(found)

# Replace your original function with this fuzzy version
func find_text_in_data(data : Variant, path: String, text : String) -> Variant:
	return FuzzyTextMatcher.find_text_in_data_fuzzy(data, path, text, 0.85)

func show_event_info(info : Dictionary):
	var item_image = load(info.path + info.item)
	var event_image = load(info.path + info.event)
	# Show Item image
	%ItemPreview.texture = item_image
	# Show Item event
	var item_event_image = event_image_scene.instantiate()
	item_event_image.texture = event_image
	INFO_CONTAINER.add_child(item_event_image)
	
	if !disable_anims:
		play_random_animation()


#region Tamanimations

# Animation data with weights
var animations = [
	{"name": "points", "chances": 100},
	{"name": "points_and_you", "chances": 5}
]

func play_random_animation():
	var selected_animation = get_weighted_random_animation()
	if selected_animation != "":
		TAMANIMATION_PLAYER.play(selected_animation)
		print("Playing animation: ", selected_animation)

func get_weighted_random_animation() -> String:
	if animations.is_empty():
		print("No animations defined!")
		return ""
	
	# Calculate total weight
	var total_weight = 0
	for anim in animations:
		total_weight += anim.chances
	
	# Generate random number between 0 and total_weight
	var random_value = randi() % total_weight
	
	# Find which animation this random value corresponds to
	var current_weight = 0
	for anim in animations:
		current_weight += anim.chances
		if random_value < current_weight:
			return anim.name
	
	# Fallback (shouldn't reach here)
	return animations[0].name

#endregion


#region Save/Load Settings

var config = ConfigFile.new()

func save_settings():
	config.set_value("program", "screen", current_screen)
	config.set_value("program", "keep_alive", keep_alive)
	config.set_value("program", "always_on_top", always_on_top)
	config.set_value("program", "disable_anims", disable_anims)
	
	config.set_value("career", "character", selected_character.name if selected_character != {} else "")
	
	config.save(SETTINGS_FILE)
	print("Settings saved!")

func load_settings():
	var err = config.load(SETTINGS_FILE)
	
	if err != OK:
		print("No settings file found, using defaults")
		return
	
	# Load values with defaults if they don't exist
	current_screen = config.get_value("program", "screen", 0)
	%CurrentScreenLabel.text = str(current_screen + 1)
	keep_alive = config.get_value("program", "keep_alive", false)
	%AutoToggle.set_pressed_no_signal(keep_alive)
	always_on_top = config.get_value("program", "always_on_top", false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	%AlwaysOnTopToggle.set_pressed_no_signal(always_on_top)
	disable_anims = config.get_value("program", "disable_anims", false)
	%DisableAnims.set_pressed_no_signal(disable_anims)
	
	# Load character
	var saved_selected_character = config.get_value("career", "character", "")
	if saved_selected_character != "":
		selected_character = find_dict_by_name(character_data, saved_selected_character)
		if selected_character.has("preview"):
			set_selected_character_ui()
	
	print("Settings loaded!")

func find_dict_by_name(dict_list: Array, target_name: String) -> Dictionary:
	for dict in dict_list:
		if dict.has("name") and dict["name"] == target_name:
			return dict
	return {}

func set_selected_character_ui():
	%ClickToChangeLabel.show()
	%CareerCharacterLabel.text = "Career: " + selected_character.name
	%SelectedCharacter.texture = load("res://CharacterData/" + selected_character.preview)

func _on_settings_menu_button_pressed() -> void:
	%Settings.show()


func _on_close_settings_button_pressed() -> void:
	%Settings.hide()

#endregion

func _on_character_select_button_pressed() -> void:
	%CharacterSelect.show()

func _on_close_character_select_button_pressed() -> void:
	%CharacterSelect.hide()

func on_character_selected(character):
	selected_character = character
	set_selected_character_ui()
	_on_close_character_select_button_pressed()
	save_settings()
