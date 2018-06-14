
# not only does this remove existing maps, but also adds the actions if they do not exist
func reset_input_maps(num_players):
	for i in range(num_players):
		var prefix = 'p%d_' % (i+1)
		for action in ['up', 'down', 'left', 'right', 'fire', 'next', 'prev']:
			var ac = prefix + action
			if InputMap.has_action(ac):
				InputMap.erase_action(ac)
			InputMap.add_action(ac)

func list_maps(action):
	print('maps for %s:' % action)
	var maps = InputMap.get_action_list(action)
	for m in maps:
		print(m.as_text(), m)

func assign_keyboard_mouse_input(prefix):
	var wasd_maps = [['up','w'], ['up','space'], ['down','s'], ['left','a'], ['right','d']]
	assign_input_maps(prefix, wasd_maps, 'key')
	var mouse_maps = [['fire',1], ['prev',BUTTON_WHEEL_UP], ['next',BUTTON_WHEEL_DOWN]]
	assign_input_maps(prefix, mouse_maps, 'mouse')

func assign_gamepad_input(prefix, device_index):
	var joystick_maps = [['down',[1,1]], ['left',[0,-1]], ['right',[0,1]]]
	assign_input_maps(prefix, joystick_maps, 'gamepad_move', device_index)
	# use the godot input map editor to obtain these indices
	var button_maps = [['up',0], ['down',13], ['left',14], ['right',15],
		['fire',5], ['up',4], ['prev',2], ['next',3]]
	assign_input_maps(prefix, button_maps, 'gamepad', device_index)
	
func assign_input_maps(prefix, maps, type, device_index=null):
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
			#event.device = device_index
			event.axis = map[1][0]
			event.axis_value = map[1][1]
		elif type == 'gamepad':
			event = InputEventJoypadButton.new()
			#event.device = device_index
			event.button_index = map[1]
		else:
			assert false
		var ac = prefix + map[0]
		#print('adding map ' + ac + ', ' + event.as_text())
		assert InputMap.has_action(ac)
		InputMap.action_add_event(ac, event)
