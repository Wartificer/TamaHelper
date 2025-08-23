extends Node

# Calculate Levenshtein distance between two strings
static func levenshtein_distance(s1: String, s2: String) -> int:
	var len1 = s1.length()
	var len2 = s2.length()
	
	# Create a matrix
	var matrix = []
	for i in range(len1 + 1):
		matrix.append([])
		for j in range(len2 + 1):
			matrix[i].append(0)
	
	# Initialize first row and column
	for i in range(len1 + 1):
		matrix[i][0] = i
	for j in range(len2 + 1):
		matrix[0][j] = j
	
	# Fill the matrix
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if s1[i-1] == s2[j-1] else 1
			matrix[i][j] = min(
				matrix[i-1][j] + 1,      # deletion
				matrix[i][j-1] + 1,      # insertion
				matrix[i-1][j-1] + cost  # substitution
			)
	
	return matrix[len1][len2]

# Calculate similarity percentage (0.0 to 1.0)
static func similarity_percentage(s1: String, s2: String) -> float:
	if s1 == s2:
		return 1.0
	
	var max_len = max(s1.length(), s2.length())
	if max_len == 0:
		return 1.0
	
	var distance = levenshtein_distance(s1, s2)
	return 1.0 - (float(distance) / float(max_len))

# Find best match from a list of candidates
static func find_best_match(target: String, candidates: Array, min_similarity: float = 0.8) -> Dictionary:
	var best_match = ""
	var best_similarity = 0.0
	var best_index = -1
	
	for i in range(candidates.size()):
		var candidate = candidates[i]
		var similarity = similarity_percentage(target.to_lower(), candidate.to_lower())
		
		if similarity > best_similarity and similarity >= min_similarity:
			best_similarity = similarity
			best_match = candidate
			best_index = i
	
	return {
		"match": best_match,
		"similarity": best_similarity,
		"index": best_index,
		"found": best_index != -1
	}

# Alternative: Jaro-Winkler similarity (better for typos at the beginning)
static func jaro_similarity(s1: String, s2: String) -> float:
	if s1 == s2:
		return 1.0
	
	var len1 = s1.length()
	var len2 = s2.length()
	
	if len1 == 0 or len2 == 0:
		return 0.0
	
	var match_distance = (max(len1, len2) / 2) - 1
	if match_distance < 1:
		match_distance = 1
	
	var s1_matches = []
	var s2_matches = []
	for i in len1:
		s1_matches.append(false)
	for i in len2:
		s2_matches.append(false)
	
	var matches = 0
	var transpositions = 0
	
	# Find matches
	for i in range(len1):
		var start = max(0, i - match_distance)
		var end = min(i + match_distance + 1, len2)
		
		for j in range(start, end):
			if s2_matches[j] or s1[i] != s2[j]:
				continue
			s1_matches[i] = true
			s2_matches[j] = true
			matches += 1
			break
	
	if matches == 0:
		return 0.0
	
	# Count transpositions
	var k = 0
	for i in range(len1):
		if not s1_matches[i]:
			continue
		while not s2_matches[k]:
			k += 1
		if s1[i] != s2[k]:
			transpositions += 1
		k += 1
	
	return (float(matches) / len1 + float(matches) / len2 + 
			float(matches - transpositions/2) / matches) / 3.0

# Find fuzzy match in your specific data structure
static func find_text_in_data_fuzzy(data: Variant, type : String, text: String, threshold: float = 0.85) -> Variant:
	var cleaned_text = clean_ocr_text(text)
	var best_match = null
	var best_similarity = 0.0
	
	# First pass: try exact match
	for item in data:
		for event in item.events:
			if event.name.to_lower() == cleaned_text.to_lower():
				return {
					"name": event.name,
					"image": get_support_image(item) if type == "support" else Utils.to_snake_case(item.name),
					"type": type,
					"texts": event.text,
					"similarity": 1.0
				}
	
	# Second pass: fuzzy matching
	for item in data:
		for event in item.events:
			var similarity = similarity_percentage(cleaned_text.to_lower(), event.name.to_lower())
			if similarity > best_similarity and similarity >= threshold:
				best_similarity = similarity
				best_match = {
					"name": event.name,
					"image": Utils.to_snake_case(item.name) if type == "character" else get_support_image(item),
					"type": type,
					"texts": event.text,
					"similarity": similarity
				}
	
	return best_match if best_match else false

static func get_support_image(item : Dictionary) -> String:
	var filename = ""
	filename += item.type.capitalize() + "_"
	filename += item.rarity.to_upper() + "_"
	filename += Utils.to_snake_case(item.name)
	return filename

# Alternative version that returns all matches above threshold (useful for debugging)
static func find_all_matches_in_data(data: Variant, path: String, text: String, threshold: float = 0.85) -> Array:
	var cleaned_text = clean_ocr_text(text)
	var matches = []
	
	for item in data:
		for event in item.events:
			for event_key in event.keys():
				var similarity = similarity_percentage(cleaned_text.to_lower(), event_key.to_lower())
				
				if similarity >= threshold:
					matches.append({
						"item": item.preview,
						"path": path,
						"event": event[event_key],
						"similarity": similarity,
						"matched_key": event_key,
						"original_text": text
					})
	
	# Sort by similarity (highest first)
	matches.sort_custom(func(a, b): return a.similarity > b.similarity)
	return matches

# Clean common OCR errors
static func clean_ocr_text(text: String) -> String:
	var cleaned = text
	
	# Common OCR substitutions
	var substitutions = {
		"|": "I",
		"0": "O",
		"5": "S",
		"1": "I",
		"8": "B",
		"6": "G",
		"2": "Z"
	}
	
	# Apply substitutions only at word boundaries to avoid false positives
	for wrong in substitutions:
		var correct = substitutions[wrong]
		# Replace at the beginning of words
		cleaned = cleaned.replace(" " + wrong, " " + correct)
		# Replace at the start of string
		if cleaned.begins_with(wrong):
			cleaned = correct + cleaned.substr(1)
	
	return cleaned.strip_edges()
