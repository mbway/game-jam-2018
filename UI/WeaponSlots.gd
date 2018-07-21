extends VBoxContainer

# the key to getting the images to scale correctly is to:
# Expand: on
# Stretch Mode: Keep Aspect
# Min Size: (0, 20)

# to place on the right hand side, set scale.x = -1 for the whole container


var base_height = 30
var selected_height = 50

var base_alpha = 0.5
var selected_alpha = 0.9


func select_weapon(name):
	if not has_node(name):
		print('cannot select %s because not in the tray' % name)
		return
	else:
		for w in get_children():
			if w.name == name:
				w.rect_min_size.y = selected_height
				w.modulate.a = selected_alpha
			else:
				w.rect_min_size.y = base_height
				w.modulate.a = base_alpha

func add_weapon(w):
	if has_node(w.name):
		print('weapon %s already added' % w.name)
		return
		
	var r = TextureRect.new()
	r.name = w.name
	r.texture = w.texture
	r.expand = true
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	r.rect_min_size.y = base_height
	r.modulate.a = base_alpha
	
	add_child(r)
	
func remove_weapon(name):
	for w in get_children():
		if w.name == name:
			remove_child(w)
			w.queue_free()
			return

func _on_Player_weapon_equiped(weapon):
	add_weapon(weapon)

func _on_Player_weapon_unequiped(weapon_name):
	remove_weapon(weapon_name)

func _on_Player_weapon_selected(name):
	select_weapon(name)
