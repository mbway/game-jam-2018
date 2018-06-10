extends VBoxContainer

# the key to getting the images to scale correctly is to:
# Expand: on
# Stretch Mode: Keep Aspect
# Min Size: (0, 20)

#TODO
export (bool) var mirrored = false

var base_height = 30
var selected_height = 50

var base_alpha = 0.5
var selected_alpha = 0.9

func _ready():
	select_weapon('Pistol')

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
	r.texture = w.texture
	r.expand = true
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	r.rect_min_size.y = base_height
	r.modulate.a = base_alpha
	
	add_child(r)