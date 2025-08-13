# AssetLoader.gd
extends Node


var custom_font: Font
var custom_mascot: Texture2D

# Valid font extensions
const FONT_EXTENSIONS = ["ttf", "otf", "woff", "woff2"]
# Valid image extensions  
const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "svg", "bmp"]
var is_mascot_animated: bool = false

func _ready():
	load_assets()

func load_assets():
	var assets_path = get_assets_path()
	print("Checking for custom assets in: ", assets_path)
	
	# Check if assets directory exists
	if not DirAccess.dir_exists_absolute(assets_path):
		print("Custom directory not found at: ", assets_path)
		return
	
	# Load font
	load_font(assets_path)
	
	# Load mascot
	load_mascot(assets_path)

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
				
				var texture = load_image_from_path(image_path)
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

func load_image_from_path(path: String) -> Texture2D:
	var image = Image.new()
	var error = image.load(path)
	
	if error != OK:
		print("Failed to load image: ", path, " Error: ", error)
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

# Helper functions to access the loaded assets from other scripts
func get_font() -> Font:
	return custom_font

func get_mascot() -> Texture2D:
	return custom_mascot

func has_font() -> bool:
	return custom_font != null

func has_mascot() -> bool:
	return custom_mascot != null
