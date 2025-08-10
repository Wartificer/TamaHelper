extends Node

var default_color_c : Color = Color(0.039, 0.851, 1) ## Default cyan
var default_color_m : Color = Color(0.93, 0.44, 1) ## Default magenta

## Sets of pixels to check to detect choices on screen
var checks : Array[Dictionary] = [
	{
		"pixels": [
			{"pos": Vector2(290, 635), "color": Color.from_string("#9adc2e", default_color_c)},
			{"pos": Vector2(290, 745), "color": Color.from_string("#ffcc18", default_color_m)},
		],
		"text_areas": [
			{"pos": Vector2(240, 200), "size": Vector2(364, 44)},
			#{"pos": Vector2(310, 610), "size": Vector2(460, 70)},
			#{"pos": Vector2(310, 720), "size": Vector2(460, 70)},
		],
		"name": "2ch",
		"label": "2 Choices",
	},
	{
		"pixels": [
			{"pos": Vector2(290, 524), "color": Color.from_string("#9adc2e", default_color_c)},
			{"pos": Vector2(290, 634), "color": Color.from_string("#ffcc18", default_color_m)},
			{"pos": Vector2(290, 746), "color": Color.from_string("#ff83b8", default_color_m)},
		],
		"text_areas": [
			{"pos": Vector2(240, 200), "size": Vector2(364, 44)},
		],
		"name": "3ch",
		"label": "3 Choices",
	},
]

## Checks if the capture has matching pixels from the items above
func check_matching_pixels(screen_size : Vector2, img : Image) -> Dictionary:
	var result : Dictionary = {}
	for check in checks:
		var pixels_match : bool = true
		for pixel in check.pixels:
			#print(pixel.pos)
			var scaled_pixel_position = scale_position_to_screen(screen_size, pixel.pos)
			#print(scaled_pixel_position)
			if img.get_pixel(scaled_pixel_position.x, scaled_pixel_position.y) != pixel.color:
				pixels_match = false
		if pixels_match:
			return check
	return result

#region Pixel Scaling

# Reference resolution (the resolution your positions are designed for)
const REFERENCE_WIDTH = 1920
const REFERENCE_HEIGHT = 1080

# Get the current screen size
func get_screen_size() -> Vector2:
	return DisplayServer.screen_get_size()

# Convert position from reference resolution to current screen resolution
func scale_position_to_screen(screen_size, reference_pos: Vector2) -> Vector2:	
	# Calculate scaling factors
	var scale_x = screen_size.x / float(REFERENCE_WIDTH)
	var scale_y = screen_size.y / float(REFERENCE_HEIGHT)
	#print(screen_size)
	#print(REFERENCE_HEIGHT)
	
	# Scale the position
	var scaled_pos = Vector2(
		reference_pos.x * scale_x,
		reference_pos.y * scale_y
	)
	
	# Round to nearest integer for pixel-perfect positioning
	return Vector2(round(scaled_pos.x), round(scaled_pos.y))

#endregion

## Gets text inside the areas from the matched check
func get_image_texts(screen_size : Vector2, matched : Dictionary, img : Image):
	var texts : Array[String] = []
	# For each "text_area" in a matched check
	for text_area in matched.text_areas:
		var scaled_pixel_position = scale_position_to_screen(screen_size, text_area.pos)
		var scaled_area_size = scale_position_to_screen(screen_size, text_area.size)
		# Extract an image of the area
		var text_area_image = img.get_region(Rect2(scaled_pixel_position.x, scaled_pixel_position.y, scaled_area_size.x, scaled_area_size.y))

		# Extract text from the image area
		var text : String = await OCRManager.extract_text_from_image_async(text_area_image)
		#print("Extracted text: " + text)
		texts.push_back(text)
	return texts
	
