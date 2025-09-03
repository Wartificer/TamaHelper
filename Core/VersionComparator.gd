extends RefCounted
class_name VersionComparator

# Returns true if version2 is greater than version1
static func is_version_greater(version1: String, version2: String) -> bool:
	var parsed_v1 = parse_version(version1)
	var parsed_v2 = parse_version(version2)
	
	# Compare major version
	if parsed_v2.major > parsed_v1.major:
		return true
	elif parsed_v2.major < parsed_v1.major:
		return false
	
	# Compare minor version
	if parsed_v2.minor > parsed_v1.minor:
		return true
	elif parsed_v2.minor < parsed_v1.minor:
		return false
	
	# Compare patch version
	if parsed_v2.patch > parsed_v1.patch:
		return true
	elif parsed_v2.patch < parsed_v1.patch:
		return false
	
	# Compare suffix (alpha < beta < rc < stable)
	return compare_suffix(parsed_v1.suffix, parsed_v2.suffix) < 0

# Parse version string into components
static func parse_version(version: String) -> Dictionary:
	var result = {
		"major": 0,
		"minor": 0,
		"patch": 0,
		"suffix": ""
	}
	
	# Clean the version string
	version = version.strip_edges()
	
	# Extract suffix (letters at the end)
	var suffix_match = RegEx.new()
	suffix_match.compile(r"([a-zA-Z]+)$")
	var suffix_result = suffix_match.search(version)
	if suffix_result:
		result.suffix = suffix_result.get_string(1).to_lower()
		version = version.substr(0, version.length() - result.suffix.length())
	
	# Split version by dots
	var parts = version.split(".")
	
	# Parse major, minor, patch
	if parts.size() >= 1:
		result.major = parts[0].to_int()
	if parts.size() >= 2:
		result.minor = parts[1].to_int()
	if parts.size() >= 3:
		result.patch = parts[2].to_int()
	
	return result

# Compare suffixes: alpha < beta < rc < stable (empty)
# Returns: -1 if suffix1 < suffix2, 0 if equal, 1 if suffix1 > suffix2
static func compare_suffix(suffix1: String, suffix2: String) -> int:
	var suffix_order = {
		"a": 0, "alpha": 0,
		"b": 1, "beta": 1,
		"rc": 2,
		"": 3  # Stable version (no suffix)
	}
	
	var order1 = suffix_order.get(suffix1, -1)
	var order2 = suffix_order.get(suffix2, -1)
	
	# Handle unknown suffixes
	if order1 == -1:
		order1 = 2  # Treat unknown as RC level
	if order2 == -1:
		order2 = 2
	
	if order1 < order2:
		return -1
	elif order1 > order2:
		return 1
	else:
		return 0

# Convenience method for checking minimum version requirement
static func meets_minimum_version(current_version: String, minimum_version: String) -> bool:
	return is_version_greater(minimum_version, current_version) or current_version == minimum_version
