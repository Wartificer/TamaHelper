extends PanelContainer

func present(index : int, text : String):
	add_theme_stylebox_override("panel", load("res://Theme/"+str(index+1)+"ChoicePanel.tres"))
	$MarginContainer/HBoxContainer/TextureRect.texture = load("res://Images/horseshoe-" + str(index + 1) + ".png")
	$MarginContainer/HBoxContainer/RichTextLabel.bbcode_text = Utils.process_text(text)
