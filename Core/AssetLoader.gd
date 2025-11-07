# AssetLoader.gd
extends Node


var custom_font: Font
var custom_mascot: Texture2D
var custom_missing_image: Texture2D

# Valid font extensions
const FONT_EXTENSIONS = ["ttf", "otf", "woff", "woff2"]
# Valid image extensions  
const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "svg", "bmp"]
var is_mascot_animated: bool = false

func _ready():
	load_assets()

func load_assets():
	custom_missing_image = load("res://Images/missing-image.png")
	var assets_path = get_assets_path()
	print("Checking for custom assets in: ", assets_path)
	
	# Check if assets directory exists
	if not DirAccess.dir_exists_absolute(assets_path):
		print("Custom directory not found at: ", assets_path)
		return
	
	# Load missing image
	load_missimg(assets_path)
	# Load font
	load_font(assets_path)
	# Load mascot
	load_mascot(assets_path)

func get_base_path() -> String:
	if OS.has_feature("editor"):
		# In editor, use res://data/
		return ProjectSettings.globalize_path("res://").get_base_dir() + "/"
	else:
		# In production, use executable_path/data/
		var exe_path = OS.get_executable_path().get_base_dir()
		return exe_path + "/"

func get_data_path() -> String:
	if OS.has_feature("editor"):
		# In editor, use res://data/
		return ProjectSettings.globalize_path("res://").get_base_dir() + "/data/"
	else:
		# In production, use executable_path/data/
		var exe_path = OS.get_executable_path().get_base_dir()
		return exe_path + "/data/"

func get_assets_path() -> String:
	if OS.has_feature("editor"):
		# In editor, use user://assets/
		return "user://assets/"
	else:
		# In production, use executable_path/assets/
		var exe_path = OS.get_executable_path().get_base_dir()
		return exe_path + "/assets/"

func load_font(base_path: String):
	var dir = DirAccess.open(base_path)
	if dir == null:
		print("Failed to open directory: ", base_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Check if filename starts with "font" (case insensitive)
		if file_name.to_lower().begins_with("font"):
			var extension = file_name.get_extension().to_lower()
			
			# Check if it has a valid font extension
			if extension in FONT_EXTENSIONS:
				var font_path = base_path + file_name
				print("Found custom font: ", font_path)
				
				var font_resource = load_font_from_path(font_path)
				if font_resource:
					custom_font = font_resource
					apply_font()
					print("Successfully loaded custom font: ", file_name)
					break
				else:
					print("Failed to load font: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func load_missimg(base_path: String):
	var dir = DirAccess.open(base_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Check if filename starts with "missing_image" (case insensitive)
		if file_name.to_lower().begins_with("missing-image"):
			var extension = file_name.get_extension().to_lower()
			
			# Check if it has a valid image extension
			if extension in IMAGE_EXTENSIONS:
				var image_path = base_path + file_name
				print("Found custom missing_image: ", image_path)
				
				var texture = load_image_from_fullpath(image_path)
				if texture:
					custom_missing_image = texture
					print("Successfully loaded custom missing_image: ", file_name)
					# You can add a signal here to notify other parts of your code
					missing_image_loaded.emit(custom_missing_image)
					break
				else:
					print("Failed to load missing_image: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func load_mascot(base_path: String):
	var dir = DirAccess.open(base_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Check if filename starts with "mascot" (case insensitive)
		if file_name.to_lower().begins_with("mascot"):
			var extension = file_name.get_extension().to_lower()
			
			# Check if it has a valid image extension
			if extension in IMAGE_EXTENSIONS:
				var image_path = base_path + file_name
				print("Found custom mascot: ", image_path)
				
				var texture = load_image_from_fullpath(image_path)
				if texture:
					custom_mascot = texture
					print("Successfully loaded custom mascot: ", file_name)
					# You can add a signal here to notify other parts of your code
					mascot_loaded.emit(custom_mascot)
					break
				else:
					print("Failed to load mascot: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func load_font_from_path(path: String) -> Font:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Could not open font file: ", path)
		return null
	
	var font_data = file.get_buffer(file.get_length())
	file.close()
	
	var font_file = FontFile.new()
	font_file.data = font_data
	
	# Verify the font loaded correctly
	if font_file.get_font_name() == "":
		print("Invalid font data in file: ", path)
		return null
	
	return font_file

# Method to scan subfolders and load "data.json" from each one
func load_data_json_from_subfolders(relative_folder_path: String) -> Array:
	var base_path = get_data_path()
	
	# Construct full folder path
	var full_folder_path = base_path.path_join(relative_folder_path)
	
	# Debug print to verify path
	print("Looking for subfolders with data.json in: ", full_folder_path)
	
	# Check if directory exists
	if not DirAccess.dir_exists_absolute(full_folder_path):
		push_error("Directory not found: " + full_folder_path)
		return []
	
	# Open directory
	var dir = DirAccess.open(full_folder_path)
	if dir == null:
		push_error("Failed to open directory: " + full_folder_path)
		return []
	
	var json_data_array: Array = []
	
	# Start reading directory contents
	dir.list_dir_begin()
	var item_name = dir.get_next()
	
	while item_name != "":
		# Check if it's a directory (subfolder)
		if dir.current_is_dir() and item_name != "." and item_name != "..":
			# Construct path to data.json in this subfolder
			var subfolder_path = full_folder_path.path_join(item_name)
			var data_json_path = subfolder_path.path_join("data.json")
			
			# Check if data.json exists in this subfolder
			if FileAccess.file_exists(data_json_path):
				# Load JSON data using our helper method
				var json_data = load_json_from_fullpath(data_json_path)
				if json_data != null:
					json_data_array.append(json_data)
				else:
					print("Warning: Failed to load data.json from folder: ", item_name)
			else:
				print("Warning: No data.json found in folder: ", item_name)
		
		item_name = dir.get_next()
	
	# Sort by folder name for consistent ordering
	json_data_array.sort_custom(func(a, b): return a.name < b.name)
	
	return json_data_array

# Method to scan folder and load all JSON files into an array
func load_all_json_from_folder(relative_folder_path: String) -> Array:
	var base_path = get_data_path()
	
	# Construct full folder path
	var full_folder_path = base_path.path_join(relative_folder_path)
	
	# Check if directory exists
	if not DirAccess.dir_exists_absolute(full_folder_path):
		print("Directory not found: " + full_folder_path)
		return []
	
	# Open directory
	var dir = DirAccess.open(full_folder_path)
	if dir == null:
		print("Failed to open directory: " + full_folder_path)
		return []
	
	var json_data_array: Array = []
	
	# Start reading directory contents
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		print(file_name)
		# Check if it's a file (not a directory) and has .json extension
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
			# Construct full file path
			var file_path = full_folder_path.path_join(file_name)
			
			# Load JSON data using our existing method
			var json_data = load_json_from_fullpath(file_path)
			if json_data != null:
				json_data_array.append(json_data)
		
		file_name = dir.get_next()
	
	print(json_data_array.size())
	return json_data_array

# Method to load JSON data from external path
func load_json_from_path(relative_path: String) -> Variant:
	# Get the base path (project folder in editor, executable folder when exported)
	var base_path = get_data_path()
	
	# Construct full path
	var full_path = base_path.path_join(relative_path)
	
	# Check if file exists
	if not FileAccess.file_exists(full_path):
		push_error("JSON file not found: " + full_path)
		return null
	
	# Open and read the file
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: " + full_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse JSON: " + full_path + " Error at line " + str(json.error_line) + ": " + json.error_string)
		return null
	
	return json.data

# Method to load JSON data from external path
func load_json_from_fullpath(full_path: String) -> Variant:
	# Check if file exists
	if not FileAccess.file_exists(full_path):
		push_error("JSON file not found: " + full_path)
		return null
	
	# Open and read the file
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: " + full_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse JSON: " + full_path + " Error at line " + str(json.error_line) + ": " + json.error_string)
		return null
	
	return json.data

func load_image_from_path(path: String) -> Texture2D:
	var base_path = get_data_path()
	
	var full_path = base_path + path
	
	var image = Image.new()
	var error = image.load(full_path)
	
	if error != OK:
		print("Failed to load image: ", full_path, " Error: ", error)
		return null
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func load_image_from_fullpath(full_path: String) -> Texture2D:
	var image = Image.new()
	var error = image.load(full_path)
	
	if error != OK:
		print("Failed to load image: ", full_path, " Error: ", error)
		return null
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func apply_font():
	if not custom_font:
		return
	
	# Get the current default theme or create one
	var theme = preload("res://Theme/Theme.tres")
	if not theme:
		theme = Theme.new()
	
	# Set the custom font as the default font
	theme.default_font = custom_font
	
	# Apply the theme to the main window/scene tree
	if get_tree().current_scene:
		get_tree().current_scene.theme = theme
	
	# Also set it for the main window if available
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MINIMIZED:
		get_window().theme = theme
	
	print("Applied custom font to theme")

# Signal that other nodes can connect to
signal mascot_loaded(texture: Texture2D)

signal missing_image_loaded(texture: Texture2D)

# Helper functions to access the loaded assets from other scripts
func get_font() -> Font:
	return custom_font

func get_mascot() -> Texture2D:
	return custom_mascot

func has_font() -> bool:
	return custom_font != null

func has_mascot() -> bool:
	return custom_mascot != null
