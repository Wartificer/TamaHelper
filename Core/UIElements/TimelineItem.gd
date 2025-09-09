extends Control

@onready var border_container = $PanelContainer/Control/BorderedContainer

var item_count = 0

func set_data(data : Dictionary, scenario : Dictionary, show_label : bool = false):
	if show_label:
		$Control/Label.text = data.date.label
		$Control/Label.show()
	set_items(data.items, scenario)

func set_items(items : Array, scenario: Dictionary):
	for item in items:
		item_count += 1
		var texture_rect : TextureRect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if item.icon.begins_with("{i}"):
			texture_rect.texture = load("res://Images/" + item.icon.replace("{i}", ""))
		else:
			texture_rect.texture = AssetLoader.load_image_from_path(Utils.to_snake_case("scenarios/" + scenario.name) + "/race_images/" + item.icon)
		texture_rect.connect("mouse_entered", on_item_mouse_enter.bind(item))
		texture_rect.connect("mouse_exited", on_item_mouse_exit.bind(item))
		$PanelContainer/HBoxContainer.add_child(texture_rect)

func get_icon(factor : String):
	if factor == "Speed":
		return "res://Images/icon-speed.tres"
	elif factor == "Stamina":
		return "res://Images/icon-stamina.tres"
	elif factor == "Power":
		return "res://Images/icon-power.tres"
	elif factor == "Guts":
		return "res://Images/icon-guts.tres"
	elif factor == "Wit":
		return "res://Images/icon-wit.tres"
	elif factor == "beach":
		return "res://Images/icon-beach.png"
	elif factor == "inspiration":
		return "res://Images/icon-inspiration.png"
	elif factor == "skill-up":
		return "res://Images/icon-skill-up.png"
	elif factor == "raffle":
		return "res://Images/carrot.png"
	return "res://Images/icon-random.tres"

func on_item_mouse_enter(data):
	get_parent().owner.show_tooltip(data)
	
func on_item_mouse_exit(data):
	get_parent().owner.hide_tooltip()

func activate():
	border_container.theme_type_variation = "TimelineBorderedPanel"
	#z_index = 1

func deactivate():
	border_container.theme_type_variation = "TimelinePanel"
	#z_index = 0
