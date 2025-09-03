extends Node

# Auto-update system for Godot 4 app
class_name DataUpdater

signal update_progress(progress: float, message: String)
signal update_complete()
signal update_impossible()
signal update_failed(error: String)

const GITHUB_REPO = "Wartificer/TamaHelper"
const MANIFEST_URL = "https://raw.githubusercontent.com/%s/master/manifest.json" % GITHUB_REPO
const RAW_BASE_URL = "https://raw.githubusercontent.com/%s/master/data/" % GITHUB_REPO

var data_path = AssetLoader.get_data_path()
var local_manifest_path = AssetLoader.get_base_path() + "manifest.json"

var _files_to_update
var _remote_manifest
signal update_available()
		
func _ready():
	# Ensure data directory exists
	if not DirAccess.dir_exists_absolute(data_path):
		DirAccess.open("user://").make_dir_recursive("data")

# Main function to check and update data
func check_for_updates() -> void:
	update_progress.emit(0.0, "Checking for updates...")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_manifest_received)
	
	var error = http_request.request(MANIFEST_URL)
	if error != OK:
		update_failed.emit("Failed to request manifest")
		http_request.queue_free()

func _on_manifest_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var http_request = get_children()[-1] as HTTPRequest
	http_request.queue_free()
	
	if response_code != 200:
		update_failed.emit("Failed to fetch manifest: HTTP " + str(response_code))
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		update_failed.emit("Failed to parse manifest JSON")
		return
	
	var remote_manifest = json.data
	var local_manifest = _load_local_manifest()
	
	var files_to_update = _compare_manifests(local_manifest, remote_manifest)
	
	if files_to_update.is_empty():
		update_progress.emit(1.0, "No updates needed")
		#update_complete.emit()
		return
	else:
		#print(remote_manifest)
		if !VersionComparator.meets_minimum_version(remote_manifest.min_app_version if remote_manifest.has("min_app_version") else ProjectSettings.get_setting("application/config/version", "1.0.0"), ProjectSettings.get_setting("application/config/version", "1.0.0")):
			update_impossible.emit()
			return
		_files_to_update = files_to_update
		_remote_manifest = remote_manifest
		update_available.emit()

func _load_local_manifest() -> Dictionary:
	var file = FileAccess.open(local_manifest_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	var content = file.get_as_text()
	file.close()
	
	if json.parse(content) == OK:
		return json.data
	return {}

func _save_local_manifest(manifest: Dictionary):
	var file = FileAccess.open(local_manifest_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(manifest))
		file.close()

func _compare_manifests(local: Dictionary, remote: Dictionary) -> Array[Dictionary]:
	var updates : Array[Dictionary] = []
	
	for category in remote:
		if category == "min_app_version":
			continue
		var remote_items = remote[category] as Dictionary
		var local_items = local.get(category, {}) as Dictionary
		
		for item_name in remote_items:
			var remote_hash = remote_items[item_name]
			var local_hash = local_items.get(item_name, "")
			
			if remote_hash != local_hash:
				updates.append({
					"category": category,
					"name": item_name,
					"hash": remote_hash
				})
	
	return updates

func _download_updates(files_to_update: Array = _files_to_update, remote_manifest: Dictionary = _remote_manifest):
	var total_files = files_to_update.size()
	var completed_files = 0
	
	update_progress.emit(0.1, "Starting downloads...")
	
	for file_info in files_to_update:
		await _download_file(file_info)
		completed_files += 1
		var progress = 0.1 + (completed_files / float(total_files)) * 0.9
		update_progress.emit(progress, "Downloaded %d/%d files" % [completed_files, total_files])
	
	# Save updated manifest
	_save_local_manifest(remote_manifest)
	
	#update_progress.emit(1.0, "Update complete!")
	update_complete.emit()

func _download_file(file_info: Dictionary) -> void:
	var category = file_info.category
	var name = file_info.name
	
	match category:
		"characters":
			await _download_character_files(name)
		"supports":
			await _download_support_files(name)
		"scenarios":
			await _download_scenario_folder(name)

func _download_character_files(name: String) -> void:
	# Download JSON file
	var json_url = RAW_BASE_URL + "characters/%s.json" % name
	var json_path = data_path + "characters/%s.json" % name
	await _download_single_file(json_url, json_path)
	
	# Check if PNG exists locally, if not, try to download it
	var png_path = data_path + "characters/%s.png" % name
	var icon_png_path = data_path + "characters/%s-icon.png" % name
	if not FileAccess.file_exists(png_path):
		var png_url = RAW_BASE_URL + "characters/%s.png" % name
		var icon_png_url = RAW_BASE_URL + "characters/%s-icon.png" % name
		await _download_single_file_optional(png_url, png_path)
		await _download_single_file_optional(icon_png_url, icon_png_path)

func _download_support_files(name: String) -> void:
	# Download JSON file
	var json_url = RAW_BASE_URL + "supports/%s.json" % name
	var json_path = data_path + "supports/%s.json" % name
	await _download_single_file(json_url, json_path)
	
	# Check if PNG exists locally, if not, try to download it
	var png_path = data_path + "supports/%s.png" % name
	if not FileAccess.file_exists(png_path):
		var png_url = RAW_BASE_URL + "supports/%s.png" % name
		await _download_single_file_optional(png_url, png_path)

func _download_single_file(url: String, local_path: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Create a signal that we can await directly
	var download_finished = func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			_save_file(local_path, body)
		http_request.queue_free()
	
	http_request.request_completed.connect(download_finished)
	http_request.request(url)
	
	# Wait for the signal to be emitted
	await http_request.request_completed
func _download_scenario_folder(scenario_name: String) -> void:
	print("Downloading scenario folder: ", scenario_name)
	
	# Create scenario directory
	var scenario_dir = data_path + "scenarios/%s/" % scenario_name
	if not DirAccess.dir_exists_absolute(scenario_dir):
		DirAccess.open("user://").make_dir_recursive(scenario_dir)
	
	# Get list of files in the remote scenario folder using GitHub API
	var files_to_download = await _get_scenario_files_list(scenario_name)
	print("Files found in scenario folder: ", files_to_download)
	
	# Download each file in the scenario folder
	for file_name in files_to_download:
		var remote_url = RAW_BASE_URL + "scenarios/%s/%s" % [scenario_name, file_name]
		var local_file_path = scenario_dir + file_name
		
		print("Downloading file: ", file_name)
		# Always download when scenario hash changes (since we're here, something changed)
		await _download_single_file(remote_url, local_file_path)

func _get_scenario_files_list(scenario_name: String) -> Array:
	# Use GitHub API to get the list of files in the scenario folder
	var api_url = "https://api.github.com/repos/%s/contents/data/scenarios/%s" % [GITHUB_REPO, scenario_name]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var files_list = []
	
	var download_finished = func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			var json = JSON.new()
			var parse_result = json.parse(body.get_string_from_utf8())
			
			if parse_result == OK:
				var file_data = json.data
				if file_data is Array:
					for item in file_data:
						if item.has("name") and item.has("type") and item["type"] == "file":
							files_list.append(item["name"])
		http_request.queue_free()
	
	http_request.request_completed.connect(download_finished)
	
	# Add headers for private repos if needed
	var headers = []
	#if GITHUB_TOKEN != "":
		#headers.append("Authorization: token " + GITHUB_TOKEN)
	
	http_request.request(api_url, headers)
	await http_request.request_completed
	
	return files_list

func _download_single_file_optional(url: String, local_path: String) -> void:
	# This version doesn't fail if the file doesn't exist (404)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var download_finished = func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			_save_file(local_path, body)
		# Ignore 404 errors for optional files like PNGs
		elif response_code == 404:
			print("Optional file not found: ", url)
		http_request.queue_free()
	
	http_request.request_completed.connect(download_finished)
	http_request.request(url)
	await http_request.request_completed

func _save_file(path: String, content: PackedByteArray):
	# Ensure directory exists
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.open("user://").make_dir_recursive(dir_path)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(content)
		file.close()

# Usage example
func start_update_check():
	update_progress.connect(_on_update_progress)
	update_complete.connect(_on_update_complete)
	update_failed.connect(_on_update_failed)
	
	check_for_updates()

func _on_update_progress(progress: float, message: String):
	print("Update progress: %.1f%% - %s" % [progress * 100, message])

func _on_update_complete():
	print("Update completed successfully!")

func _on_update_failed(error: String):
	print("Update failed: ", error)
