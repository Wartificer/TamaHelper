extends VBoxContainer

var event_text_scene = load("res://Core/UIElements/EventText.tscn")
func present(texts : Array):
	for i in texts.size():
		var text = texts[i]
		var event_text_scene = event_text_scene.instantiate()
		event_text_scene.present(i, text)
		add_child(event_text_scene)
