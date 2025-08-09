# OCR_Manager.gd
# Tesseract OCR with threading support
extends Node

signal ocr_completed(text: String)
signal ocr_failed(error: String)

var _thread: Thread
var _mutex: Mutex
var _should_exit: bool = false
var _ocr_queue: Array = []
var _pending_requests: Dictionary = {}
var _request_counter: int = 0

func _ready():
	_thread = Thread.new()
	_mutex = Mutex.new()
	_thread.start(_thread_function)

func _exit_tree():
	# Signal thread to exit
	_mutex.lock()
	_should_exit = true
	_mutex.unlock()
	
	# Wait for thread to finish
	if _thread.is_started():
		_thread.wait_to_finish()

# Thread function that processes OCR requests
func _thread_function():
	while true:
		# Check for exit condition
		_mutex.lock()
		if _should_exit:
			_mutex.unlock()
			break
		
		# Get next request if available
		var ocr_request = null
		if not _ocr_queue.is_empty():
			ocr_request = _ocr_queue.pop_front()
		_mutex.unlock()
		
		if ocr_request:
			# Process the OCR request
			_process_ocr_request(ocr_request)
		else:
			# Sleep briefly if no work available
			OS.delay_msec(10)

# Process OCR request in thread
func _process_ocr_request(request: Dictionary):
	var image = request.image as Image
	var temp_path = request.temp_path as String
	var request_id = request.request_id as int
	
	var result = _thread_extract_text_tesseract(image, temp_path)
	
	# Send result back to main thread
	call_deferred("_handle_ocr_result", request_id, result)

# Tesseract OCR in thread
func _thread_extract_text_tesseract(image: Image, temp_path: String) -> Dictionary:
	var absolute_path = ProjectSettings.globalize_path(temp_path)
	
	# Save the image temporarily
	image = preprocess_image_for_ocr(image)
	var error = image.save_png(temp_path)
	if error != OK:
		return {"success": false, "error": "Failed to save temporary image: " + str(error)}
	
	# Prepare tesseract command with quiet option
	var output = []
	var tesseract_args = [absolute_path, "stdout", "quiet"]  # -q for quiet mode
	
	# Execute tesseract without showing window
	var exit_code = OS.execute("tesseract", tesseract_args, output, true, false)
	
	# Clean up temporary file
	DirAccess.remove_absolute(absolute_path)
	
	if exit_code == 0:
		var extracted_text = ""
		for line in output:
			# Filter out diagnostic messages
			var clean_line = line.strip_edges()
			if not _is_diagnostic_message(clean_line):
				extracted_text += line
		
		return {"success": true, "text": _clean_ocr_text(extracted_text)}
	else:
		return {"success": false, "error": "Tesseract failed with exit code: " + str(exit_code)}

# Helper function to identify diagnostic messages
func _is_diagnostic_message(line: String) -> bool:
	var diagnostic_patterns = [
		"Estimating resolution as",
		"Warning:",
		"Error:",
		"Tesseract Open Source OCR Engine",
		"Page segmentation modes:",
		"OCR Engine modes:",
		"OEM",
		"PSM"
	]
	
	for pattern in diagnostic_patterns:
		if line.begins_with(pattern):
			return true
	
	return false

# Helper function to clean the extracted text
func _clean_ocr_text(text: String) -> String:
	# Remove excessive whitespace and normalize line endings
	var cleaned = text.strip_edges()
	
	# Replace multiple consecutive newlines with single newlines
	var regex = RegEx.new()
	regex.compile("\\n{3,}")  # 3 or more newlines
	cleaned = regex.sub(cleaned, "\n\n", true)  # Replace with double newline
	
	# Replace multiple consecutive spaces with single spaces
	regex.compile(" {2,}")  # 2 or more spaces
	cleaned = regex.sub(cleaned, " ", true)  # Replace with single space
	
	return cleaned

# Handle OCR result on main thread
func _handle_ocr_result(request_id: int, result: Dictionary):
	if _pending_requests.has(request_id):
		var request_data = _pending_requests[request_id]
		_pending_requests.erase(request_id)
		
		if result.success:
			request_data.result = result.text
			request_data.completed = true
		else:
			request_data.error = result.error
			request_data.completed = true
			push_error("OCR Error: " + result.error)

# Main OCR function - queues work and returns result when complete
func extract_text_tesseract(image: Image, temp_path: String = "user://temp_ocr_image.png") -> String:
	# Generate unique request ID
	_request_counter += 1
	var request_id = _request_counter
	
	# Create request data
	var request_data = {
		"result": "",
		"error": "",
		"completed": false
	}
	
	# Store pending request
	_pending_requests[request_id] = request_data
	
	# Queue the OCR request
	var request = {
		"image": image,
		"temp_path": temp_path + str(request_id) + ".png",  # Unique filename
		"request_id": request_id
	}
	
	_mutex.lock()
	_ocr_queue.append(request)
	_mutex.unlock()
	
	# Wait for completion
	while not request_data.completed:
		await get_tree().process_frame
	
	# Return result
	if request_data.error != "":
		return ""
	else:
		return request_data.result

# Utility function to preprocess image for better OCR results
func preprocess_image_for_ocr(image: Image) -> Image:
	# Convert to grayscale for better OCR
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
	
	return processed_image

# Check if OCR queue is busy
func is_ocr_processing() -> bool:
	_mutex.lock()
	var busy = not _ocr_queue.is_empty()
	_mutex.unlock()
	return busy

# Get number of pending OCR requests
func get_queue_size() -> int:
	_mutex.lock()
	var size = _ocr_queue.size()
	_mutex.unlock()
	return size
