class_name OCRManager
extends RefCounted

# For async operations, we need a node-based singleton
static var _singleton: OCRManagerSingleton

static func get_singleton() -> OCRManagerSingleton:
	if not _singleton:
		_singleton = OCRManagerSingleton.new()
		# Add to scene tree so it can handle threading
		var main = Engine.get_main_loop() as SceneTree
		if main and main.current_scene:
			main.current_scene.add_child(_singleton)
	return _singleton

static var temp_counter: int = 0

# ASYNC versions - these don't freeze the app
static func extract_text_from_image_async(image: Image) -> String:
	return await get_singleton()._extract_text_from_image_async(image)

static func extract_text_from_file_async(image_path: String) -> String:
	return await get_singleton()._extract_text_from_file_async(image_path)

static func extract_text_from_texture_async(texture: ImageTexture) -> String:
	return await get_singleton()._extract_text_from_texture_async(texture)

static func extract_text_advanced_async(image_path: String, language: String = "eng", page_seg_mode: int = 3) -> String:
	return await get_singleton()._extract_text_advanced_async(image_path, language, page_seg_mode)

# SYNC versions - these will freeze the app (use only for testing or single operations)
static func extract_text_from_file(image_path: String) -> String:
	var global_path = ProjectSettings.globalize_path(image_path)
	return _run_tesseract(global_path)

# Extract text from Image resource
static func extract_text_from_image(image: Image) -> String:
	# Save image to temp file
	var temp_path = _get_temp_image_path()
	
	var processed_image = image.duplicate()
	# Simple grayscale conversion
	for x in range(processed_image.get_width()):
		for y in range(processed_image.get_height()):
			var pixel = processed_image.get_pixel(x, y)
			var gray = (pixel.r + pixel.g + pixel.b) / 3.0
			processed_image.set_pixel(x, y, Color(gray, gray, gray, pixel.a))
	
	# Optional: Scale up small images (OCR works better on larger images)
	if processed_image.get_width() < 300 or processed_image.get_height() < 300:
		var scale_factor = max(300.0 / processed_image.get_width(), 300.0 / processed_image.get_height())
		processed_image.resize(
			int(processed_image.get_width() * scale_factor),
			int(processed_image.get_height() * scale_factor),
			Image.INTERPOLATE_LANCZOS
		)
	
	processed_image.save_png(temp_path)
		
	# Extract text
	var result = _run_tesseract(temp_path)
	
	if !OS.is_debug_build() or !Utils.save_temp_image:
		# Clean up temp file
		DirAccess.remove_absolute(temp_path)
	
	return result

# Extract text from ImageTexture
static func extract_text_from_texture(texture: ImageTexture) -> String:
	var image = texture.get_image()
	return extract_text_from_image(image)

# Main function that calls Tesseract
static func _run_tesseract(image_path: String) -> String:
	var tesseract_path = ProjectSettings.globalize_path("res://tesseract/tesseract.exe")
	var tessdata_path = ProjectSettings.globalize_path("res://tesseract/tessdata")
	
	# Prepare command arguments
	var args = [
		"--tessdata-dir", tessdata_path,
		"-l", "eng",  # Language (change as needed)
		image_path,
		"stdout",  # Output to stdout instead of file
		"quiet"
	]
	
	# Execute Tesseract (changed last parameter from true to false to hide CMD window)
	var output = []
	var exit_code = OS.execute(tesseract_path, args, output, true, false)
	if exit_code != 0:
		push_error("Tesseract failed with exit code: " + str(exit_code))
		if output.size() > 0:
			push_error("Error output: " + str(output))
		return ""
	
	# Join output lines and return
	if output.size() > 0:
		var string = "\n".join(output).strip_edges()
		return clean_extracted_text(string)
	else:
		return ""

static func clean_extracted_text(input_string: String) -> String:
	# Remove any trailing whitespace first
	var cleaned = input_string.strip_edges()
	
	# Split by multiple newlines (2 or more) and take only the first part
	var parts = cleaned.split("\n\n", false, 1)
	if parts.size() > 0:
		cleaned = parts[0]
	
	# Also handle cases with multiple spaces (3 or more) followed by content
	# This regex finds 3+ spaces followed by any character and removes everything from that point
	var regex = RegEx.new()
	regex.compile("\\s{3,}.*")
	cleaned = regex.sub(cleaned, "", true)
	
	# Final cleanup to remove any remaining trailing whitespace
	return cleaned.strip_edges()

# Alternative simpler version if you prefer:
static func clean_extracted_text_simple(input_string: String) -> String:
	# Split by double newline and take first part
	var first_part = input_string.split("\n\n")[0]
	# Remove any trailing/leading whitespace
	return first_part.strip_edges()

# Generate unique temp file path
static func _get_temp_image_path() -> String:
	temp_counter += 1
	var temp_dir = ProjectSettings.globalize_path("res://temp_images/")
	
	# Ensure temp directory exists
	if not DirAccess.dir_exists_absolute(temp_dir):
		DirAccess.make_dir_recursive_absolute(temp_dir)
	
	return temp_dir + "temp_ocr_" + str(temp_counter) + ".png"

# Advanced: Extract text with custom options
static func extract_text_advanced(image_path: String, language: String = "eng", page_seg_mode: int = 3) -> String:
	var tesseract_path = ProjectSettings.globalize_path("res://tesseract/tesseract.exe")
	var tessdata_path = ProjectSettings.globalize_path("res://tesseract/tessdata")
	var global_image_path = ProjectSettings.globalize_path(image_path)
	
	var args = [
		"--tessdata-dir", tessdata_path,
		"-l", language,
		"--psm", str(page_seg_mode),  # Page segmentation mode
		global_image_path,
		"stdout"
	]
	
	var output = []
	var exit_code = OS.execute(tesseract_path, args, output, true, false)  # Changed to false
	
	if exit_code != 0:
		push_error("Tesseract failed with exit code: " + str(exit_code))
		return ""
	
	if output.size() > 0:
		return "\n".join(output).strip_edges()
	else:
		return ""

# Get available languages
static func get_available_languages() -> Array[String]:
	var tesseract_path = ProjectSettings.globalize_path("res://tesseract/tesseract.exe")
	var tessdata_path = ProjectSettings.globalize_path("res://tesseract/tessdata")
	
	var args = ["--tessdata-dir", tessdata_path, "--list-langs"]
	var output = []
	var exit_code = OS.execute(tesseract_path, args, output, true, false)  # Changed to false
	
	if exit_code != 0:
		return ["eng"]  # Fallback
	
	var languages: Array[String] = []
	for line in output:
		var lang = line.strip_edges()
		if lang != "" and lang != "List of available languages (1):":
			languages.append(lang)
	
	return languages

# Node-based singleton for async operations
class OCRManagerSingleton extends Node:
	
	# Async version of extract_text_from_image
	func _extract_text_from_image_async(image: Image) -> String:
		return await _run_in_thread(func(): return OCRManager.extract_text_from_image(image))
	
	# Async version of extract_text_from_file  
	func _extract_text_from_file_async(image_path: String) -> String:
		return await _run_in_thread(func(): return OCRManager.extract_text_from_file(image_path))
	
	# Async version of extract_text_from_texture
	func _extract_text_from_texture_async(texture: ImageTexture) -> String:
		return await _run_in_thread(func(): return OCRManager.extract_text_from_texture(texture))
	
	# Async version of extract_text_advanced
	func _extract_text_advanced_async(image_path: String, language: String, page_seg_mode: int) -> String:
		return await _run_in_thread(func(): return OCRManager.extract_text_advanced(image_path, language, page_seg_mode))
	
	# Generic function to run any callable in a thread
	func _run_in_thread(callable: Callable) -> String:
		var thread = Thread.new()
		var mutex = Mutex.new()
		var result_data = {"text": "", "finished": false}
		
		# Thread function
		var thread_func = func():
			var result = callable.call()
			mutex.lock()
			result_data.text = result
			result_data.finished = true
			mutex.unlock()
		
		# Start thread
		thread.start(thread_func)
		
		# Wait for completion
		while true:
			await get_tree().process_frame
			mutex.lock()
			var finished = result_data.finished
			var text = result_data.text
			mutex.unlock()
			
			if finished:
				thread.wait_to_finish()
				return text
		return ""
