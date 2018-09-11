extends LineEdit

var history_index = 0
onready var terminal = get_node('../../../')

# _input rather than _gui_input so that the event can be accepted _before_ the default handler for LineEdit gets hold of it!
func _input(event):
	if Input.is_action_just_pressed('terminal_toggle'):
		accept_event() # don't treat as input

	elif has_focus() and event is InputEventKey:
		var k = event.scancode
		if not [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT].has(k):
			history_index = 0 # no longer navigating history because content was inserted

		if event.pressed and not event.is_echo(): # disregard key repeats
			if k == KEY_TAB:
				terminal.handle_autocomplete()
				accept_event() # don't handle as regular input
			elif k == KEY_UP:
				history_index = terminal.move_in_history(history_index-1)
				accept_event() # don't handle as regular input
			elif k == KEY_DOWN:
				history_index = terminal.move_in_history(history_index+1)
				accept_event() # don't handle as regular input