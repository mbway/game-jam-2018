extends LineEdit

var history_index = 0

func _input(event):
	if Input.is_action_just_pressed('terminal_toggle'):
		accept_event() # don't treat as input
		
	elif event is InputEventKey:
		var k = event.scancode
		if not [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT].has(k):
			history_index = 0 # no longer navigating history
			
		if event.pressed and not event.is_echo(): # disregard key repeats
			if k == KEY_TAB:
				get_node('../../../').handle_autocomplete(self)
				accept_event() # don't treat as input
			elif k == KEY_UP:
				history_index = get_node('../../../').move_in_history(history_index-1)
			elif k == KEY_DOWN:
				history_index = get_node('../../../').move_in_history(history_index+1)