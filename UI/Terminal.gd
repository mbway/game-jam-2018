extends CanvasLayer

onready var G = globals

onready var text = $PanelContainer/VBoxContainer/RichTextLabel
onready var line = $PanelContainer/VBoxContainer/LineEdit

const red = Color('#ff0000')
const green = Color('#00ff00')

var active = false
var cmd_history = []
var history_index = -1 # used when scrolling through command history with the arrow keys


func _process(delta):
	if Input.is_action_just_pressed('terminal_toggle'):
		active = not active
		#$PanelContainer.visible = visible
		$AnimationPlayer.play('SlideDown' if active else 'SlideUp')
		line.editable = active
		if active:
			line.focus_mode = Control.FOCUS_ALL # can grab focus
			line.grab_focus()
		else:
			line.focus_mode = Control.FOCUS_NONE # cannot grab focus
	
	if active:
		# mirror output sent to stdout or stderr by G.log and G.log_err
		while not G.output_queue.empty():
			var item = G.output_queue.pop_front()
			var is_error = item[0]
			var msg = item[1] + '\n'
			if item[0]: # is_error
				log_error(msg)
			else:
				log_text(msg)

func _on_LineEdit_text_entered(input):
	if not text.text.empty() and not text.text.ends_with('\n'):
		text.newline()
	text.push_color(green)
	text.add_text('> ' + input + '\n')
	text.pop()
	line.clear()
	if input != '': # don't print an error just because the input was empty
		handle_command(input)
	text.scroll_to_line(text.get_line_count()-1)

func log_text(txt):
	text.add_text(txt)

func log_error(txt):
	text.push_color(red)
	text.add_text(txt)
	text.pop()

# pass table as a 2D list, each inner list is a row. Must have the same length for each row
func display_table(t, bbcode=false):
	if len(t) == 0:
		return
	var cols = len(t[0])
	text.push_table(cols)
	for row in t:
		assert len(row) == cols
		for c in row:
			text.push_cell()
			if bbcode:
				text.append_bbcode(c)
			else:
				text.add_text(c)
			text.pop()
	text.pop()


# command : [[arg_name, arg_name, ...], description]
const commands = {
	'help'        : [[], 'displays information about each command.'],
	'clear'       : [[], 'clears the terminal.'],

	'exit'        : [[], 'quit the game.'],
	'menu'        : [[], 'return to the main menu.'],
	'reload'      : [[], 'reload the current scene. Useful to apply options which do not automatically refresh.'],
	'quick_start' : [[], 'run the QuickStart scene'],

	'set_opt'     : [['name', 'value'], 'set an option.'],
	'get_opts'    : [[], 'get the current options.'],
	'reset_opts'  : [[], 'reset all options to their default values.']
}


# takes and input line and parses it into a usable form,
# eg: parse_command('setop a b') --> ['setop', {'name': 'a', 'value': 'b'}, ['a', 'b']]
func parse_command(input):
	var cmd
	var args_list = []

	if not ' ' in input:
		cmd = input
	else:
		var res = input.split(' ', false, 1) # divisor, allow_empty, maxsplits
		cmd = res[0]
		if len(res) > 1:
			args_list = res[1].split(' ', false)

	if not commands.has(cmd):
		log_error('unknown command: "%s"!' % cmd)
		return null

	var expected_args = commands[cmd][0]
	if len(args_list) != len(expected_args):
		log_error('command "%s" expects %s arguments but %s given!\n' % [cmd, len(expected_args), len(args_list)])
		log_error('usage: %s\n' % command_usage(cmd))
		return null

	var args = {}
	for i in range(len(expected_args)):
		args[expected_args[i]] = args_list[i]

	return [cmd, args, args_list]


func command_usage(cmd):
	return '%s %s' % [cmd, PoolStringArray(commands[cmd][0]).join(' ')]


func handle_command(input):
	cmd_history.append(input)
	var res = parse_command(input)
	if res == null:
		return
	var cmd = res[0]
	var args = res[1]
	var args_list = res[2]

	if cmd == 'help':
		var t = []
		for cmd in commands.keys():
			t.append([command_usage(cmd), commands[cmd][1]])
		display_table(t)
	elif cmd == 'clear':
		text.clear()

	elif cmd == 'exit':
		get_tree().quit()
	elif cmd == 'menu':
		get_tree().change_scene('res://MainMenu/MainMenu.tscn')
	elif cmd == 'reload':
		get_tree().reload_current_scene()
	elif cmd == 'quick_start':
		get_tree().change_scene('res://Utils/QuickStart.tscn')


	elif cmd == 'set_opt':
		G.settings.set(args['name'], args['value'])
	elif cmd == 'get_opts':
		var t = []
		for name in G.settings.get_names():
			var v = G.settings.get(name)
			if v == true or v == false:
				v = '[color=%s]%s[/color]' % ['#00ff00' if v else '#ff0000', str(v)]
			t.append([name, str(v), G.settings.get_description(name)])
		display_table(t, true)
	elif cmd == 'reset_opts':
		G.settings.reset()

func get_prefix_matches(prefix, list):
	var matches = []
	for item in list:
		if item.begins_with(prefix):
			matches.append(item)
	return matches

func set_line(txt):
	line.text = txt
	line.caret_position = len(txt)

func handle_autocomplete():
	var t = line.text
	var words = t.split(' ', true)
	if len(words) > 1: # command already typed
		if words[0] == 'set_opt' and len(words) == 2:
			var matches = get_prefix_matches(words[1], G.settings.get_names())
			if len(matches) == 1:
				set_line('%s %s ' % [words[0], matches[0]])
	else: # command not yet typed
		var matches = get_prefix_matches(t, commands.keys())
		if len(matches) == 1:
			set_line(matches[0] + ' ')

func move_in_history(history_index):
	var l = len(cmd_history)
	history_index = int(clamp(history_index, -l, 0))
	set_line('' if history_index == 0 else cmd_history[l+history_index])
	return history_index
