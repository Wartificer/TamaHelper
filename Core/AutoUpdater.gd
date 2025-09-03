extends Node
# Auto-update system for Godot 4 app

signal update_progress(progress: float, message: String)
signal update_complete()
signal update_failed(error: String)

const GITHUB_REPO = "Wartificer/TamaHelper"
const MANIFEST_URL = "https://raw.githubusercontent.com/%s/main/manifest.json" % GITHUB_REPO
const RAW_BASE_URL = "https://raw.githubusercontent.com/%s/main/data/" % GITHUB_REPO

var data_path = AssetLoader.get_data_path()
var local_manifest_path = "user://local_manifest.json"

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
		print(error)
		update_failed.emit("Failed to request manifest")
		http_request.queue_free()

func _on_manifest_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var http_request = get_children()[-1] as HTTPRequest
	http_request.queue_free()
	
	if response_code != 200:
		update_failed.emit("Failed to fetch manifest: HTTP " + str(response_code))
		return
	print(response_code)
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		update_failed.emit("Failed to parse manifest JSON")
		return
	
	var remote_manifest = json.data
	var local_manifest = _load_local_manifest()
	print(json.data)
	
	var files_to_update = _compare_manifests(local_manifest, remote_manifest)
	
	if files_to_update.is_empty():
		update_progress.emit(1.0, "No updates needed")
		update_complete.emit()
		return
	
	_download_updates(files_to_update, remote_manifest)

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
	var updates = []
	
	for category in remote:
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

func _download_updates(files_to_update: Array, remote_manifest: Dictionary):
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
	
	update_progress.emit(1.0, "Update complete!")
	update_complete.emit()

func _download_file(file_info: Dictionary) -> void:
	var category = file_info.category
	var name = file_info.name
	var url = ""
	var local_path = ""
	
	match category:
		"characters":
			url = RAW_BASE_URL + "characters/%s.json" % name
			local_path = data_path + "characters/%s.json" % name
		"supports":
			url = RAW_BASE_URL + "supports/%s.json" % name  
			local_path = data_path + "supports/%s.json" % name
		"scenarios":
			# For scenarios, we need to download the entire folder
			await _download_scenario_folder(name)
			return
	
	await _download_single_file(url, local_path)

func _download_single_file(url: String, local_path: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var completed = false
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			_save_file(local_path, body)
		completed = true
		http_request.queue_free()
	)
	
	http_request.request(url)
	
	# Wait for completion
	while not completed:
		await get_tree().process_frame

func _download_scenario_folder(scenario_name: String) -> void:
	# First, get the data.json file to see what else is in the folder
	var data_json_url = RAW_BASE_URL + "scenarios/%s/data.json" % scenario_name
	var data_json_path = data_path + "scenarios/%s/data.json" % scenario_name
	
	# Create scenario directory
	var scenario_dir = data_path + "scenarios/%s/" % scenario_name
	if not DirAccess.dir_exists_absolute(scenario_dir):
		DirAccess.open("user://").make_dir_recursive(scenario_dir.get_base_dir())
	
	await _download_single_file(data_json_url, data_json_path)
	
	# You might want to extend this to download other files in the scenario folder
	# based on what's listed in data.json or by making additional API calls

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
