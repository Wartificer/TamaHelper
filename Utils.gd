extends Node

func to_snake_case(text : String):
	return text.replacen(" ", "_")
# Text processor class or add these to your existing script


#region Text Processing

var icon_size = "30"
# Define your dictionaries and colors
var replacement_dict = {
	"Mood+": "[img width="+icon_size+"]res://Images/icon-mood-up.tres[/img]",
	"Mood-": "[img width="+icon_size+"]res://Images/icon-mood-down.tres[/img]",
	"Energy+": "[img width="+icon_size+"]res://Images/icon-energy-up.tres[/img]",
	"Energy-": "[img width="+icon_size+"]res://Images/icon-energy-down.tres[/img]",
	"sp+": "[img width="+icon_size+"]res://Images/icon-sp.tres[/img]",
	"sp-": "[img width="+icon_size+"]res://Images/icon-sp.tres[/img]",
	"possible": "[img width="+icon_size+"]res://Images/icon-possible.tres[/img]",
	"hint": "[img width="+icon_size+"]res://Images/icon-hint.tres[/img]",
	"bond+": "[img width="+icon_size+"]res://Images/icon-friend-up.tres[/img]",
	"bond-": "[img width="+icon_size+"]res://Images/icon-friend-down.tres[/img]",
	"fans+": "[img width="+icon_size+"]res://Images/icon-fans.tres[/img]",
	"Speed+": "[img width="+icon_size+"]res://Images/icon-speed.tres[/img]",
	"Speed-": "[img width="+icon_size+"]res://Images/icon-speed.tres[/img]",
	"Stamina+": "[img width="+icon_size+"]res://Images/icon-stamina.tres[/img]",
	"Stamina-": "[img width="+icon_size+"]res://Images/icon-stamina.tres[/img]",
	"Power+": "[img width="+icon_size+"]res://Images/icon-power.tres[/img]",
	"Power-": "[img width="+icon_size+"]res://Images/icon-power.tres[/img]",
	"Guts+": "[img width="+icon_size+"]res://Images/icon-guts.tres[/img]",
	"Guts-": "[img width="+icon_size+"]res://Images/icon-guts.tres[/img]",
	"Wit+": "[img width="+icon_size+"]res://Images/icon-wit.tres[/img]",
	"Wit-": "[img width="+icon_size+"]res://Images/icon-wit.tres[/img]",
	"1stats": "[img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"2stats": "[img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"3stats": "[img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"4stats": "[img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"All+": "[img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"All-": "[img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img][img width="+icon_size+"]res://Images/icon-random.tres[/img]",
	"healaff": "[img width="+icon_size+"]res://Images/icon-heal.tres[/img]",
	"healall": "[img width="+icon_size+"]res://Images/icon-heal-all.tres[/img]",
	# Add more replacements as needed
}

var numbers_positive = [
	{"from": 20, "string": "[img width="+icon_size+"]res://Images/icon-up++.tres[/img]"},
	{"from": 11, "string": "[img width="+icon_size+"]res://Images/icon-up+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-up.tres[/img]"},
]
var numbers_negative = [
	{"from": 20, "string": "[img width="+icon_size+"]res://Images/icon-down++.tres[/img]"},
	{"from": 11, "string": "[img width="+icon_size+"]res://Images/icon-down+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-down.tres[/img]"},
]
var energy_numbers_positive = [
	{"from": 30, "string": "[img width="+icon_size+"]res://Images/icon-up++.tres[/img]"},
	{"from": 21, "string": "[img width="+icon_size+"]res://Images/icon-up+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-up.tres[/img]"},
]
var energy_numbers_negative = [
	{"from": 30, "string": "[img width="+icon_size+"]res://Images/icon-down++.tres[/img]"},
	{"from": 21, "string": "[img width="+icon_size+"]res://Images/icon-down+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-down.tres[/img]"},
]
var sp_numbers_positive = [
	{"from": 50, "string": "[img width="+icon_size+"]res://Images/icon-up++.tres[/img]"},
	{"from": 26, "string": "[img width="+icon_size+"]res://Images/icon-up+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-up.tres[/img]"},
]
var sp_numbers_negative = [
	{"from": 50, "string": "[img width="+icon_size+"]res://Images/icon-down++.tres[/img]"},
	{"from": 26, "string": "[img width="+icon_size+"]res://Images/icon-down+.tres[/img]"},
	{"from": 5, "string": "[img width="+icon_size+"]res://Images/icon-down.tres[/img]"},
]

var links = {
	"Full Speed": "Increases movement speed by 50% for 10 seconds",
	"Magic Boost": "Enhances spell damage by 25%",
	# Add more links as needed
}

var color_positive = "5dff47"
var color_negative = "ff5959"
var color_possible = "e8e823"

func process_text(input_text: String) -> String:
	var processed_text = input_text
	var parts = processed_text.split("\n")
	for i in parts.size(): 
		print(parts[i])
		# Step 1: Color text after [[possible]]
		parts[i] = _color_possible_text(parts[i])
		# Step 2: Add color tags to numbers following + or - signs
		parts[i] = _add_color_to_numbers(parts[i])
		# Step 3: Process single brackets for tooltips and other types
		parts[i] = _process_single_brackets(parts[i])
		# Step 4: Replace double square brackets [[text]]
		parts[i] = _replace_double_brackets(parts[i])
	processed_text = "\n".join(parts)
	return processed_text

func _replace_double_brackets(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[\\[([^\\]]+)\\]\\]")
	
	var result = text
	var regex_result = regex.search(result)
	
	while regex_result:
		var full_match = regex_result.get_string(0)  # [[Mood+]]
		var key = regex_result.get_string(1)         # Mood+
		
		if replacement_dict.has(key):
			result = result.replace(full_match, replacement_dict[key])
		else:
			# If key not found, you can either leave it as is or replace with a default
			# For now, we'll leave it as is
			pass
		
		regex_result = regex.search(result, regex_result.get_end())
	
	return result

func _add_color_to_numbers(text: String) -> String:
	var regex = RegEx.new()
	# Matches + or - followed by one or more digits
	regex.compile("([+-])(\\d+)")
	
	var result = text
	var matches = []
	var regex_result = regex.search(result)
	
	# First, collect all matches
	while regex_result:
		matches.append({
			"start": regex_result.get_start(),
			"end": regex_result.get_end(),
			"full_match": regex_result.get_string(0),
			"sign": regex_result.get_string(1),
			"number": regex_result.get_string(2)
		})
		regex_result = regex.search(result, regex_result.get_end())
	
	# Then replace them in reverse order to maintain correct positions
	matches.reverse()
	for match in matches:
		var number_value = int(match.number)
		var color = color_positive if match.sign == "+" else color_negative
		var symbol = match.sign
		
		# Change which numbers are checked for each effect type
		var numbers_to_use = [numbers_positive, numbers_negative]
		if text.contains("[[sp+"):
			numbers_to_use = [sp_numbers_positive, sp_numbers_negative]
		elif text.contains("[[Energy"):
			numbers_to_use = [energy_numbers_positive, energy_numbers_negative]
			
		# Check if we should replace the symbol with an icon
		var numbers_array = numbers_to_use[0] if match.sign == "+" else numbers_to_use[1]
		for entry in numbers_array:
			if number_value >= entry.from:
				symbol = entry.string
				break
		
		var replacement = "[color=" + color + "]" + symbol + match.number + "[/color]"
		
		# Replace using string positions instead of replace() to avoid issues
		result = result.substr(0, match.start) + replacement + result.substr(match.end)
	
	return result

func _color_possible_text(text: String) -> String:
	var regex = RegEx.new()
	# Matches [[possible]] followed by any text until newline or end of string
	regex.compile("\\[\\[possible\\]\\]([^\\n]*)")
	
	var result = text
	var matches = []
	var regex_result = regex.search(result)
	
	# Collect all matches first
	while regex_result:
		matches.append({
			"start": regex_result.get_start(),
			"end": regex_result.get_end(),
			"full_match": regex_result.get_string(0),
			"text_after": regex_result.get_string(1)
		})
		regex_result = regex.search(result, regex_result.get_end())
	
	# Process matches in reverse order to maintain positions
	matches.reverse()
	for match in matches:
		var replacement = "[[possible]][color=" + color_possible + "]" + match.text_after + "[/color]"
		result = result.substr(0, match.start) + replacement + result.substr(match.end)
	
	return result

func _process_single_brackets(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\{([^:]+):([^}]+)\\}")
	
	var result = text
	var regex_result = regex.search(result)
	
	while regex_result:
		var full_match = regex_result.get_string(0)  # {link:Full Speed}
		var type = regex_result.get_string(1)        # link
		var value = regex_result.get_string(2)       # Full Speed
		
		var replacement = ""
		
		match type:
			"link":
				if links.has(value):
					# Create a tooltip using BBCode
					# You can customize this format based on your needs
					replacement = "[hint=" + links[value] + "]" + value + "[/hint]"
				else:
					# If link not found, just show the value without tooltip
					replacement = value
			_:
				# Unknown type, just show the value
				replacement = value
		
		result = result.replace(full_match, replacement)
		regex_result = regex.search(result, regex_result.get_end())
	
	return result

#endregion
