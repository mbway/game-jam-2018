extends VBoxContainer

# the key to getting the images to scale correctly is to:
# Expand: on
# Stretch Mode: Keep Aspect
# Min Size: (0, 20)

# to place on the right hand side, set scale.x = -1 for the whole container

onready var G = globals

var base_height = 30
var selected_height = 50

var base_alpha = 0.5
var selected_alpha = 0.9


func select_item(name):
	# note: name may be null, in which case everything in the tray should be deselected
	if name != null and not has_node(name):
		G.log_err('cannot select %s because not in the tray' % name)
		return
	else:
		for i in get_children():
			if i.name == name:
				i.rect_min_size.y = selected_height
				i.modulate.a = selected_alpha
			else:
				i.rect_min_size.y = base_height
				i.modulate.a = base_alpha

func add_item(item):
	if has_node(item.name):
		G.log_err('item %s already added' % item.name)
		return

	var r = TextureRect.new()
	r.name = item.name
	r.texture = item.texture
	r.expand = true
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	r.rect_min_size.y = base_height
	r.modulate.a = base_alpha

	add_child(r)

func remove_item(name):
	for w in get_children():
		if w.name == name:
			remove_child(w)
			w.queue_free()
			return

func _on_equiped(item):
	add_item(item)

func _on_unequiped(item):
	remove_item(item)

func _on_selected(name):
	select_item(name)

