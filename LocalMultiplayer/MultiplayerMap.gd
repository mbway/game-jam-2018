extends Node


func _ready():
	var pistol_scene = load('res://Weapons/Pistol.tscn')
	$Player.setup('p1_', $Bullets, null)#$Camera)
	$Player.equip(pistol_scene)
	
	#var a = InputMap.get_action_list('test')
	#for s in a:
	#	print(s)
	

	clear_input_maps()
	var wasd_maps = {'up':'w', 'down':'s', 'left':'a', 'right':'d'}
	assign_input_maps('p1_', wasd_maps, 'key')
	var mouse_maps = {'fire':1}
	assign_input_maps('p1_', mouse_maps, 'mouse')
	#assign_mouse_input('p1_')

func clear_input_maps():
	for prefix in ['p1_', 'p2_']:
		for action in ['up', 'down', 'left', 'right', 'fire']:
			var ac = prefix + action
			if InputMap.has_action(ac):
				InputMap.erase_action(ac)
			InputMap.add_action(ac)
			print(ac)


func assign_input_maps(prefix, maps, type):
	for action in maps.keys():
		var event = null
		if type == 'key':
			event = InputEventKey.new()
			event.scancode = OS.find_scancode_from_string(maps[action])
		elif type == 'mouse':
			event = InputEventMouseButton.new()
			event.button_index = maps[action]
		else:
			assert false
		InputMap.action_add_event(prefix + action, event)

