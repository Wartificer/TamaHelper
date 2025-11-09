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

## Auto-detect DPI scaling by comparing screen size with actual image size
func detect_dpi_scale_from_capture(reported_screen_size: Vector2, actual_image_size: Vector2) -> float:
	if actual_image_size.x <= 0 or actual_image_size.y <= 0:
		return 1.0
	
	# Calculate the ratio between what we think the screen size should be
	# and what the actual capture size is
	var scale_x = actual_image_size.x / reported_screen_size.x
	var scale_y = actual_image_size.y / reported_screen_size.y
	
	# Use the average of both scales (they should be the same for uniform DPI scaling)
	var detected_scale = (scale_x + scale_y) / 2.0
	
	# Only update cache if the detected scale seems reasonable (between 0.5 and 4.0)
	if detected_scale >= 0.5 and detected_scale <= 4.0:
		_cached_dpi_scale = detected_scale
		_dpi_cache_valid = true
	
	return detected_scale

## Get the actual screen size accounting for DPI scaling
func get_actual_screen_size(reported_screen_size: Vector2, image_size: Vector2 = Vector2.ZERO) -> Vector2:
	var dpi_scale = get_dpi_scale_factor()
	
	# If we have an actual image size, use it to detect/verify DPI scaling
	if image_size != Vector2.ZERO:
		var detected_scale = detect_dpi_scale_from_capture(reported_screen_size, image_size)
		if abs(detected_scale - dpi_scale) > 0.1:
			# Significant difference detected, use the detected scale
			dpi_scale = detected_scale
	
	return reported_screen_size * dpi_scale

## Calculates the 16:9 content area within the actual screen
func get_content_area(reported_screen_size: Vector2, image_size: Vector2 = Vector2.ZERO) -> Dictionary:
	# Get the actual screen size accounting for DPI scaling
	var actual_screen_size = get_actual_screen_size(reported_screen_size, image_size)
	
	var screen_aspect_ratio = actual_screen_size.x / actual_screen_size.y
	var content_area = {}
	
	if abs(screen_aspect_ratio - REFERENCE_ASPECT_RATIO) < 0.01:
		# Screen is 16:9 (or very close), content fills entire screen
		content_area.offset = Vector2.ZERO
		content_area.size = actual_screen_size
		content_area.scale_x = actual_screen_size.x / float(REFERENCE_WIDTH)
		content_area.scale_y = actual_screen_size.y / float(REFERENCE_HEIGHT)
	elif screen_aspect_ratio > REFERENCE_ASPECT_RATIO:
		# Screen is wider than 16:9 (e.g., ultrawide), content is pillarboxed
		var content_height = actual_screen_size.y
		var content_width = content_height * REFERENCE_ASPECT_RATIO
		content_area.offset = Vector2((actual_screen_size.x - content_width) / 2.0, 0)
		content_area.size = Vector2(content_width, content_height)
		content_area.scale_x = content_width / float(REFERENCE_WIDTH)
		content_area.scale_y = content_height / float(REFERENCE_HEIGHT)
	else:
		# Screen is taller than 16:9 (e.g., WUXGA 1920x1200), content is letterboxed
		var content_width = actual_screen_size.x
		var content_height = content_width / REFERENCE_ASPECT_RATIO
		content_area.offset = Vector2(0, (actual_screen_size.y - content_height) / 2.0)
		content_area.size = Vector2(content_width, content_height)
		content_area.scale_x = content_width / float(REFERENCE_WIDTH)
		content_area.scale_y = content_height / float(REFERENCE_HEIGHT)
	
	return content_area

## Convert position from reference resolution to actual screen position
func scale_position_to_screen(reported_screen_size: Vector2, reference_pos: Vector2, image_size: Vector2 = Vector2.ZERO) -> Vector2:
	var content_area = get_content_area(reported_screen_size, image_size)
	
	# Scale the position within the content area
	var scaled_pos = Vector2(
		reference_pos.x * content_area.scale_x,
		reference_pos.y * content_area.scale_y
	)
	
	# Add the content area offset to get the final screen position
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
func check_matching_pixels(screen_size : Vector2, img : Image) -> Dictionary:
	var result : Dictionary = {}
	var similarity_threshold : float = 0.9  # 90% similarity threshold
	
	# Use the actual image size to detect DPI scaling
	var image_size = Vector2(img.get_width(), img.get_height())
	
	# First check if we can even find the content area (basic sanity check)
	var content_area = get_content_area(screen_size, image_size)
	if content_area.size.x <= 0 or content_area.size.y <= 0:
		print("Warning: Invalid content area calculated")
		return result
	
	for check in checks:
		var pixels_match : bool = true
		for pixel in check.pixels:
			var scaled_pixel_position = scale_position_to_screen(screen_size, pixel.pos, image_size)
			
			# Ensure the scaled position is within image bounds
			if scaled_pixel_position.x < 0 or scaled_pixel_position.x >= img.get_width() or \
			   scaled_pixel_position.y < 0 or scaled_pixel_position.y >= img.get_height():
				pixels_match = false
				break
			
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
func get_image_texts(screen_size : Vector2, matched : Dictionary, img : Image, caller : Node):
	var texts : Array[String] = []
	
	# Use the actual image size to detect DPI scaling
	var image_size = Vector2(img.get_width(), img.get_height())
	
	print(matched)
	
	# For each "text_area" in a matched check
	for text_area in matched.text_areas:
		var scaled_pixel_position = scale_position_to_screen(screen_size, text_area.pos, image_size)
		var scaled_area_size = Vector2(
			text_area.size.x * get_content_area(screen_size, image_size).scale_x,
			text_area.size.y * get_content_area(screen_size, image_size).scale_y
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
		caller.debug_date(text_area_image)
		
		# Extract text from the image area
		var text : String = await OCRManager.extract_text_from_image_async(text_area_image)
		texts.push_back(text)
	
	return texts

## Helper function to debug and print content area info
func debug_content_area(screen_size: Vector2, image_size: Vector2 = Vector2.ZERO) -> void:
	var actual_screen_size = get_actual_screen_size(screen_size, image_size)
	var content_area = get_content_area(screen_size, image_size)
	var screen_aspect_ratio = actual_screen_size.x / actual_screen_size.y
	
	print("=== DPI Scaling Debug Info ===")
	print("Reported screen size: ", screen_size)
	print("Actual screen size: ", actual_screen_size)
	print("DPI scale factor: ", get_dpi_scale_factor())
	if image_size != Vector2.ZERO:
		print("Image size: ", image_size)
	print("Screen aspect ratio: ", screen_aspect_ratio)
	print("Content area offset: ", content_area.offset)
	print("Content area size: ", content_area.size)
	print("Scale factors - X: ", content_area.scale_x, " Y: ", content_area.scale_y)
	print("==============================")

## Force refresh DPI scale detection (call this if display settings change)
func refresh_dpi_cache() -> void:
	_dpi_cache_valid = false
	_cached_dpi_scale = 1.0
