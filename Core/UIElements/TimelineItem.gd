extends Control

func set_data(data : Dictionary, show_label : bool = false):
	name = data.name
	if show_label:
		var name_split = name.split(" ")
		$Label.text = name_split[name_split.size()-1]
		$Label.show()
	set_items(data.items)

func set_items(items : Array):
	for item in items:
		var texture_rect : TextureRect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.texture = load("res://" + item.icon)
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
