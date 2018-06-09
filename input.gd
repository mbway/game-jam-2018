
func clear_input_maps():
	for prefix in ['p1_', 'p2_']:
		for action in ['up', 'down', 'left', 'right', 'fire']:
			var ac = prefix + action
			if InputMap.has_action(ac):
				InputMap.erase_action(ac)
			InputMap.add_action(ac)

func list_maps(action):
	var maps = InputMap.get_action_list(action)
	for m in maps:
		print(m.as_text(), m)

func assign_keyboard_mouse_input(prefix):
	var wasd_maps = [['up','w'], ['up','space'], ['down','s'], ['left','a'], ['right','d']]
	assign_input_maps(prefix, wasd_maps, 'key')
	var mouse_maps = [['fire',1]]
	assign_input_maps(prefix, mouse_maps, 'mouse')

func assign_gamepad_input(prefix):
	var joystick_maps = [['down',[1,1]], ['left',[0,-1]], ['right',[0,1]]]
	assign_input_maps(prefix, joystick_maps, 'gamepad_move')
	# use the godot input map editor to obtain these indices
	var button_maps = [['up',0], ['down',13], ['left',14], ['right',15],
		['fire',5], ['up',4]]
	assign_input_maps(prefix, button_maps, 'gamepad')

func assign_input_maps(prefix, maps, type):
	for map in maps:
		var event = null
		if type == 'key':
			event = InputEventKey.new()
			event.scancode = OS.find_scancode_from_string(map[1])
		elif type == 'mouse':
			event = InputEventMouseButton.new()
			event.button_index = map[1]
		elif type == 'gamepad_move':
			event = InputEventJoypadMotion.new()
			event.axis = map[1][0]
			event.axis_value = map[1][1]
		elif type == 'gamepad':
			event = InputEventJoypadButton.new()
			event.button_index = map[1]
		else:
			assert false
		InputMap.action_add_event(prefix + map[0], event)