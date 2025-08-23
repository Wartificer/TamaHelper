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
var scenario_data : Variant

## Current career vars
var selected_character : Dictionary
var selected_scenario : Dictionary


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

var character_button_scene = load("res://Core/UIElements/CharacterButton.tscn")
func load_character_list():
	for character in character_data:
		var character_button = character_button_scene.instantiate()
		var image = AssetLoader.load_image_from_path("characters/" + Utils.to_snake_case(character.name) + "-icon.png")
		if !image:
			image = load("res://Images/missing-image.png")
		character_button.get_child(0).texture = image
		character_button.get_child(1).text = character.name
		character_button.pressed.connect(on_character_selected.bind(character))
		%CharacterList.add_child(character_button)

func load_scenario_list():
	for scenario in scenario_data:
		var scenario_button = character_button_scene.instantiate()
		var image = AssetLoader.load_image_from_path("scenarios/" + Utils.to_snake_case(scenario.name) + "/icon.png")
		if !image:
			image = load("res://Images/missing-image.png")
		scenario_button.get_child(0).texture = image
		scenario_button.get_child(1).text = scenario.name
		scenario_button.pressed.connect(on_scenario_selected.bind(scenario))
		%ScenarioList.add_child(scenario_button)



## Initialize OCR Manager
func _ready():
	if AssetLoader.custom_mascot:
		%Mascot.texture = AssetLoader.custom_mascot
	get_screen_size()
	character_data = AssetLoader.load_all_json_from_folder("characters")
	character_data.sort_custom(func(a, b):
		return a["name"] < b["name"]
	)
	support_data = AssetLoader.load_all_json_from_folder("supports")
	scenario_data = AssetLoader.load_data_json_from_subfolders("scenarios")
	
	#load_important_events()
	#load_g1s()
	
	load_character_list()
	load_scenario_list()
	load_settings()
	## Connect to OCR signals
	#OCRManager.ocr_completed.connect(_on_ocr_completed)
	#OCRManager.ocr_failed.connect(_on_ocr_failed)

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
	Utils.save_temp_image = !keep_alive
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


var date_position_data = {
		"text_areas": [
			{"pos": Vector2(260, 38), "size": Vector2(180, 18)},
		],
		"outlined": true,
		"debug_name": "Event"
}
var last_event_name = ""
func process_capture(capture : Image):
	# Always check date to keep timeline updated
	var date_result : Array[String] = await ImageReader.get_image_texts(screen_size, date_position_data, capture)
	print("//////////////////////////////")
	print("Extracted date: " + (" - ").join(date_result))
	update_date(date_result[0])
	
	#####################################################################
	# Check for choices
	var result = ImageReader.check_matching_pixels(screen_size, capture)
	# If there was no match, stop
	if result == {}:
		print("No choices on screen")
		return
	
	#print("MATCHING: " + result.label)
	
	## If there is something matching on screen, get the text inside the designated areas
	var texts_result : Array[String] = await ImageReader.get_image_texts(screen_size, result, capture)
	print("Extracted event name: " + (" - ").join(texts_result))
	## If the text is the same as previous text shown, stop process
	if texts_result == previous_texts_result:
		return
	
	previous_texts_result = texts_result
	if texts_result.size() > 0:
			
		# Add information to screen
		for text in texts_result:
			var found
			# Find text in character data
			found = find_text_in_data([selected_character], "character", "res://data/characters/", text)
			# Find text in scenario instead
			if !found:
				found = find_text_in_data(scenario_data, "scenario", "res://data/scenarios/", text)
			# Find text in supports instead
			if !found:
				found = find_text_in_data(support_data, "support", "res://data/supports/", text)
				
			# If an event was found for text, present it
			if found and found.name != last_event_name:
				last_event_name = found.name
				# Clear previous info
				for child in INFO_CONTAINER.get_children():
					child.queue_free()
				show_event_info(found)

# Replace your original function with this fuzzy version
func find_text_in_data(data : Variant, type : String, path: String, text : String) -> Variant:
	return FuzzyTextMatcher.find_text_in_data_fuzzy(data, type, path, text, 0.5)

var item_image_scene = load("res://Core/UIElements/ItemImage.tscn")
var event_texts_scene = load("res://Core/UIElements/EventTexts.tscn")
func show_event_info(info : Dictionary):
	var item_image = load(info.path + "images/" + info.image + ".png")
	if !item_image:
		item_image = load("res://Images/missing-image.png")
	# Show Item image
	%ItemPreview.texture = item_image
	
	# Show Item event text
	var item_event_texts = event_texts_scene.instantiate()
	item_event_texts.present(info.texts)
	INFO_CONTAINER.add_child(item_event_texts)
	
	if !disable_anims:
		play_random_animation()

func update_date(date_on_screen : String):
	for i in Utils.dates.size():
		var date = Utils.dates[i]
		if date == date_on_screen:
			var date_pos = 50 * i * -1 + 75.0
			%ImportantEventsTimeline.offset_left = date_pos
			%G1RacesTimeline.offset_left = date_pos

func show_tooltip(data):
	if data.has("terrain"):
		%TooltipLabel.text = data.name + "\n" + data.terrain + " - " + data.distance + "\n" + (" + ").join(data.factors)
	else:
		%TooltipLabel.text = (" + ").join(data.factors)
	%Tooltip.show()

func hide_tooltip():
	%Tooltip.hide()

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

# Call this function when the application is closing
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()
		get_tree().quit()

var config = ConfigFile.new()

func save_settings():
	config.set_value("program", "screen", current_screen)
	config.set_value("program", "keep_alive", keep_alive)
	config.set_value("program", "always_on_top", always_on_top)
	config.set_value("program", "disable_anims", disable_anims)
	
	# Save window position and size
	config.set_value("window", "position_x", DisplayServer.window_get_position().x)
	config.set_value("window", "position_y", DisplayServer.window_get_position().y)
	config.set_value("window", "size_x", DisplayServer.window_get_size().x)
	config.set_value("window", "size_y", DisplayServer.window_get_size().y)
	
	config.set_value("career", "character", selected_character.name if selected_character != {} else "")
	config.set_value("career", "scenario", selected_scenario.name if selected_scenario != {} else "")
	
	config.save(SETTINGS_FILE)

func load_settings():
	var err = config.load(SETTINGS_FILE)
	
	if err != OK:
		print("No settings file found, using defaults")
		return
	
	# Load window position and size
	var pos_x = config.get_value("window", "position_x", -1)
	var pos_y = config.get_value("window", "position_y", -1)
	var size_x = config.get_value("window", "size_x", -1)
	var size_y = config.get_value("window", "size_y", -1)
	
	# Only restore if valid values were saved
	if pos_x != -1 and pos_y != -1:
		DisplayServer.window_set_position(Vector2i(pos_x, pos_y))
	
	if size_x != -1 and size_y != -1:
		DisplayServer.window_set_size(Vector2i(size_x, size_y))
	
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
		if selected_character.has("name"):
			set_selected_character_ui()
	# Load scenario
	var saved_selected_scenario = config.get_value("career", "scenario", "")
	if saved_selected_scenario != "":
		saved_selected_scenario = "URA Finale"
	selected_scenario = find_dict_by_name(scenario_data, saved_selected_scenario)
	if selected_scenario.has("name"):
		set_selected_scenario_ui()

func find_dict_by_name(dict_list: Array, target_name: String) -> Dictionary:
	for dict in dict_list:
		if dict.has("name") and dict["name"] == target_name:
			return dict
	return {}

func set_selected_character_ui():
	%ClickToChangeLabel.show()
	%CareerCharacterLabel.text = selected_character.name
	%SelectedCharacter.texture = AssetLoader.load_image_from_path("characters/" + Utils.to_snake_case(selected_character.name) + "-icon.png")

func set_selected_scenario_ui():
	%ClickToChangeScenarioLabel.show()
	%CareerScenarioLabel.text = selected_scenario.name
	%SelectedScenario.texture = AssetLoader.load_image_from_path("scenarios/" + Utils.to_snake_case(selected_scenario.name) + "/icon.png")
	set_timelines()

func set_timelines():
	pass

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


func _on_scenario_select_button_pressed() -> void:
	%ScenarioSelect.show()

func _on_close_scenario_select_button_pressed() -> void:
	%ScenarioSelect.hide()

func on_scenario_selected(scenario):
	selected_scenario = scenario
	set_selected_scenario_ui()
	_on_close_scenario_select_button_pressed()
	save_settings()
