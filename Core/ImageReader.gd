extends Node
var default_color_c : Color = Color(0.039, 0.851, 1) ## Default cyan
var default_color_m : Color = Color(0.93, 0.44, 1) ## Default magenta

# Cache for DPI scaling factor
var _cached_dpi_scale : float = 1.0
var _dpi_cache_valid : bool = false
## Sets of pixels to check to detect choices on screen
var checks : Array[Dictionary] = [
	{
		"pixels": [
			{"pos": Vector2(290, 635), "color": Color.from_string("#9adc2e", default_color_c)},
			{"pos": Vector2(290, 745), "color": Color.from_string("#ffcc18", default_color_m)},
		],
		"text_areas": [
			{"pos": Vector2(242, 196), "size": Vector2(370, 50)},
			#{"pos": Vector2(310, 610), "size": Vector2(460, 70)},
			#{"pos": Vector2(310, 720), "size": Vector2(460, 70)},
		],
		"name": "2ch",
		"label": "2 Choices",
		"debug_name": "Event"
	},
	{
		"pixels": [
			{"pos": Vector2(290, 524), "color": Color.from_string("#9adc2e", default_color_c)},
			#{"pos": Vector2(290, 634), "color": Color.from_string("#ffcc18", default_color_m)},
			{"pos": Vector2(290, 746), "color": Color.from_string("#ff83b8", default_color_m)},
		],
		"text_areas": [
			{"pos": Vector2(242, 196), "size": Vector2(370, 50)},
		],
		"name": "3ch",
		"label": "3 Choices",
		"debug_name": "Event"
	},
	{
		"pixels": [
			{"pos": Vector2(290, 300), "color": Color.from_string("#9adc2e", default_color_c)},
			{"pos": Vector2(290, 745), "color": Color.from_string("#919efd", default_color_m)},
		],
		"text_areas": [
			{"pos": Vector2(242, 196), "size": Vector2(370, 50)},
		],
		"name": "5ch",
		"label": "5 Choices",
		"debug_name": "Event"
	},
]

# Reference resolution (the resolution your positions are designed for)
const REFERENCE_WIDTH = 1920
const REFERENCE_HEIGHT = 1080
const REFERENCE_ASPECT_RATIO = float(REFERENCE_WIDTH) / float(REFERENCE_HEIGHT)

var current_screen : int = 1
# Game Window configuration (position and size, fullscreen by default)
var game_window_config : Dictionary


## Gets the Windows DPI scaling factor
func get_dpi_scale_factor() -> float:
	if _dpi_cache_valid:
		return _cached_dpi_scale
	
	# Try to get DPI scaling using OS calls
	if OS.get_name() == "Windows":
		# Method 1: Try using DisplayServer to get screen DPI
		var screen_dpi = DisplayServer.screen_get_dpi()
		if screen_dpi > 0:
			# Standard DPI is 96, so scale factor is current DPI / 96
			_cached_dpi_scale = screen_dpi / 96.0
			_dpi_cache_valid = true
			return _cached_dpi_scale
		
		# Method 2: Try comparing logical vs physical screen size
		var logical_size = DisplayServer.screen_get_size()
		# This is a fallback - we'll detect it by comparing expected vs actual capture size
		_cached_dpi_scale = 1.0
	else:
		_cached_dpi_scale = 1.0
	
	_dpi_cache_valid = true
	return _cached_dpi_scale

## Get the screen offset for multi-monitor setups
func get_screen_offset() -> Vector2:
	if current_screen <= 1:
		return Vector2.ZERO
	
	var offset_x = 0
	# Calculate cumulative width of screens before the current one
	for screen_index in range(current_screen - 1):
		var screen_size = DisplayServer.screen_get_size(screen_index)
		offset_x += screen_size.x
	
	return Vector2(offset_x, 0)

## Get the game window's position relative to its screen (removing multi-monitor offset)
func get_game_window_relative_position() -> Vector2:
	if not game_window_config.has("X") or not game_window_config.has("Y"):
		return Vector2.ZERO
	
	var window_pos = Vector2(game_window_config.X, game_window_config.Y)
	var screen_offset = get_screen_offset()
	
	# Remove the screen offset to get position relative to the current screen
	return window_pos - screen_offset

## Get the game window size
func get_game_window_size() -> Vector2:
	if not game_window_config.has("Width") or not game_window_config.has("Height"):
		# Fallback to current screen size if no window config
		return DisplayServer.screen_get_size()
	
	return Vector2(game_window_config.Width, game_window_config.Height)

## Auto-detect DPI scaling by comparing screen size with actual image size
func detect_dpi_scale_from_capture(window_size: Vector2, actual_image_size: Vector2) -> float:
	if actual_image_size.x <= 0 or actual_image_size.y <= 0:
		return 1.0
	
	# Calculate the ratio between what we think the window size should be
	# and what the actual capture size is
	var scale_x = actual_image_size.x / window_size.x
	var scale_y = actual_image_size.y / window_size.y
	
	# Use the average of both scales (they should be the same for uniform DPI scaling)
	var detected_scale = (scale_x + scale_y) / 2.0
	
	# Only update cache if the detected scale seems reasonable (between 0.5 and 4.0)
	if detected_scale >= 0.5 and detected_scale <= 4.0:
		_cached_dpi_scale = detected_scale
		_dpi_cache_valid = true
	
	return detected_scale

## Get the actual window size accounting for DPI scaling
func get_actual_window_size(image_size: Vector2 = Vector2.ZERO) -> Vector2:
	var window_size = get_game_window_size()
	var dpi_scale = get_dpi_scale_factor()
	
	# If we have an actual image size, use it to detect/verify DPI scaling
	if image_size != Vector2.ZERO:
		var detected_scale = detect_dpi_scale_from_capture(window_size, image_size)
		if abs(detected_scale - dpi_scale) > 0.1:
			# Significant difference detected, use the detected scale
			dpi_scale = detected_scale
	
	return window_size * dpi_scale

## Calculates the 16:9 content area within the actual game window
func get_content_area(image_size: Vector2 = Vector2.ZERO) -> Dictionary:
	# Get the actual window size accounting for DPI scaling
	var actual_window_size = get_actual_window_size(image_size)
	
	var window_aspect_ratio = actual_window_size.x / actual_window_size.y
	var content_area = {}
	
	if abs(window_aspect_ratio - REFERENCE_ASPECT_RATIO) < 0.01:
		# Window is 16:9 (or very close), content fills entire window
		content_area.offset = Vector2.ZERO
		content_area.size = actual_window_size
		content_area.scale_x = actual_window_size.x / float(REFERENCE_WIDTH)
		content_area.scale_y = actual_window_size.y / float(REFERENCE_HEIGHT)
	elif window_aspect_ratio > REFERENCE_ASPECT_RATIO:
		# Window is wider than 16:9 (e.g., ultrawide), content is pillarboxed
		var content_height = actual_window_size.y
		var content_width = content_height * REFERENCE_ASPECT_RATIO
		content_area.offset = Vector2((actual_window_size.x - content_width) / 2.0, 0)
		content_area.size = Vector2(content_width, content_height)
		content_area.scale_x = content_width / float(REFERENCE_WIDTH)
		content_area.scale_y = content_height / float(REFERENCE_HEIGHT)
	else:
		# Window is taller than 16:9 (e.g., WUXGA 1920x1200), content is letterboxed
		var content_width = actual_window_size.x
		var content_height = content_width / REFERENCE_ASPECT_RATIO
		content_area.offset = Vector2(0, (actual_window_size.y - content_height) / 2.0)
		content_area.size = Vector2(content_width, content_height)
		content_area.scale_x = content_width / float(REFERENCE_WIDTH)
		content_area.scale_y = content_height / float(REFERENCE_HEIGHT)
	
	return content_area

## Convert position from reference resolution to actual window position
func scale_position_to_window(reference_pos: Vector2, image_size: Vector2 = Vector2.ZERO) -> Vector2:
	var content_area = get_content_area(image_size)
	
	# Scale the position within the content area
	var scaled_pos = Vector2(
		reference_pos.x * content_area.scale_x,
		reference_pos.y * content_area.scale_y
	)
	
	# Add the content area offset to get the final window position
	scaled_pos += content_area.offset
	
	# Round to nearest integer for pixel-perfect positioning
	return Vector2(round(scaled_pos.x), round(scaled_pos.y))


# Helper function to calculate color similarity (0.0 = completely different, 1.0 = identical)
func calculate_color_similarity(color1: Color, color2: Color) -> float:
	# Calculate the difference for each channel (R, G, B, A)
	var r_diff = abs(color1.r - color2.r)
	var g_diff = abs(color1.g - color2.g)
	var b_diff = abs(color1.b - color2.b)
	var a_diff = abs(color1.a - color2.a)
	
	# Calculate average difference
	var avg_diff = (r_diff + g_diff + b_diff + a_diff) / 4.0
	
	# Convert to similarity (1.0 - difference)
	return 1.0 - avg_diff

# Alternative color similarity function using Euclidean distance
func calculate_color_similarity_euclidean(color1: Color, color2: Color) -> float:
	# Calculate Euclidean distance in RGBA space
	var r_diff = color1.r - color2.r
	var g_diff = color1.g - color2.g
	var b_diff = color1.b - color2.b
	var a_diff = color1.a - color2.a
	
	var distance = sqrt(r_diff * r_diff + g_diff * g_diff + b_diff * b_diff + a_diff * a_diff)
	var max_distance = sqrt(4.0)  # Maximum possible distance in RGBA space
	
	# Convert distance to similarity
	return 1.0 - (distance / max_distance)

## Checks if the capture has matching pixels from the items above
func check_matching_pixels(img : Image) -> Dictionary:
	var result : Dictionary = {}
	var similarity_threshold : float = 0.9  # 90% similarity threshold
	
	# Use the actual image size to detect DPI scaling
	var image_size = Vector2(img.get_width(), img.get_height())
	
	# First check if we can even find the content area (basic sanity check)
	var content_area = get_content_area(image_size)
	if content_area.size.x <= 0 or content_area.size.y <= 0:
		print("Warning: Invalid content area calculated")
		return result
	
	for check in checks:
		var pixels_match : bool = true
		for pixel in check.pixels:
			var scaled_pixel_position = scale_position_to_window(pixel.pos, image_size)
			
			# Ensure the scaled position is within image bounds
			if scaled_pixel_position.x < 0 or scaled_pixel_position.x >= img.get_width() or \
			   scaled_pixel_position.y < 0 or scaled_pixel_position.y >= img.get_height():
				pixels_match = false
				break
			
			print(scaled_pixel_position)
			
			var actual_color = img.get_pixel(scaled_pixel_position.x, scaled_pixel_position.y)
			
			# Use color similarity instead of exact match
			var similarity = calculate_color_similarity(actual_color, pixel.color)
			if similarity < similarity_threshold:
				pixels_match = false
				break
		
		if pixels_match:
			return check
	
	return result

## Gets text inside the areas from the matched check
func get_image_texts(matched : Dictionary, img : Image):
	var texts : Array[String] = []
	
	# Use the actual image size to detect DPI scaling
	var image_size = Vector2(img.get_width(), img.get_height())
	
	# For each "text_area" in a matched check
	for text_area in matched.text_areas:
		var scaled_pixel_position = scale_position_to_window(text_area.pos, image_size)
		var scaled_area_size = Vector2(
			text_area.size.x * get_content_area(image_size).scale_x,
			text_area.size.y * get_content_area(image_size).scale_y
		)
		
		# Ensure the region is within image bounds
		var region_rect = Rect2(
			scaled_pixel_position.x, 
			scaled_pixel_position.y, 
			round(scaled_area_size.x), 
			round(scaled_area_size.y)
		)
		
		# Clamp the region to image bounds
		region_rect = region_rect.intersection(Rect2(0, 0, img.get_width(), img.get_height()))
		
		if region_rect.size.x <= 0 or region_rect.size.y <= 0:
			print("Warning: Text area is outside image bounds")
			texts.push_back("")
			continue
		
		# Extract an image of the area
		var text_area_image = img.get_region(region_rect)
		
		# Extract text from the image area
		var text : String = await OCRManager.extract_text_from_image_async(text_area_image)
		texts.push_back(text)
	
	return texts

## Helper function to debug and print content area info
func debug_content_area(image_size: Vector2 = Vector2.ZERO) -> void:
	var game_window_size = get_game_window_size()
	var game_window_pos = get_game_window_relative_position()
	var actual_window_size = get_actual_window_size(image_size)
	var content_area = get_content_area(image_size)
	var window_aspect_ratio = actual_window_size.x / actual_window_size.y
	
	print("=== Game Window Debug Info ===")
	print("Game window size: ", game_window_size)
	print("Game window position (relative): ", game_window_pos)
	print("Actual window size: ", actual_window_size)
	print("DPI scale factor: ", get_dpi_scale_factor())
	print("Current screen: ", current_screen)
	print("Screen offset: ", get_screen_offset())
	if image_size != Vector2.ZERO:
		print("Image size: ", image_size)
	print("Window aspect ratio: ", window_aspect_ratio)
	print("Content area offset: ", content_area.offset)
	print("Content area size: ", content_area.size)
	print("Scale factors - X: ", content_area.scale_x, " Y: ", content_area.scale_y)
	print("==============================")

## Force refresh DPI scale detection (call this if display settings change)
func refresh_dpi_cache() -> void:
	_dpi_cache_valid = false
	_cached_dpi_scale = 1.0


#region New Game Window Detection

func detect_game_window():
	var output = []
	var exit_code = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", "get-windows.ps1"], output)
	
	if exit_code == 0 and output.size() > 0:
		var json_string = ""
		for line in output:
			json_string += line + "\n"
		
		var json = JSON.new()
		var parse_result = json.parse(json_string.strip_edges())
		
		if parse_result == OK:
			var data = json.data
			for window in data:
				if window.Title == "Umamusume":
					game_window_config = window

#endregion
