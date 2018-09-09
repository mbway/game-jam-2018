extends CanvasLayer

var G = globals

onready var utils = preload('res://Utils/Utils.gd')

onready var text = $PanelContainer/VBoxContainer/RichTextLabel
onready var line = $PanelContainer/VBoxContainer/LineEdit

const red = Color('#ff0000')
const green = Color('#00ff00')

const MACRO_DIR = 'user://macros/'

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

# called when enter is pressed in the LineEdit
func run(input):
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
	if not text.text.empty() and not text.text.ends_with('\n'):
		text.newline()

func log_error(txt):
	text.push_color(red)
	log_text(txt)
	text.pop()

# pass table as a 2D list, each inner list is a row. Must have the same length for each row
# headings = true means that the first row will be formated as column headings
func display_table(t, bbcode=false, headings=false):
	if len(t) == 0:
		return
	var cols = len(t[0])
	text.push_table(cols)
	var headings_row = headings
	for row in t:
		assert len(row) == cols

		for c in row:
			text.push_cell()
			if headings_row:
				text.push_underline()

			if bbcode:
				text.append_bbcode(c)
			else:
				text.add_text(c)

			if headings_row:
				text.pop()
			text.pop()

		if headings_row:
			headings_row = false # all other rows are not headings
	text.pop()


# command : [[arg_name, arg_name, ...], description]
# commands are written 'backwards' like health_set for autocomplete reasons, otherwise set_ would end up with several autocomplete matches
const commands = {
	'help'        : [[], 'displays information about each command.'],
	'clear'       : [[], 'clears the terminal.'],
	'macro'       : [['file'], 'executes the macro file saved in the user data folder (at %s)' % MACRO_DIR],

	'exit'        : [[], 'quit the game.'],
	'menu'        : [[], 'return to the main menu.'],
	'reload'      : [[], 'reload the current scene. Useful to apply options which do not automatically refresh.'],
	'quick_start' : [[], 'run the QuickStart scene'],

	'setop'       : [['name', 'value'], 'set an option.'],
	'getops'      : [[], 'get the current options.'],
	'reset_ops'   : [[], 'reset all options to their default values.'],

	'players'     : [[], 'display the details of the current players'],
	'give'        : [['player_num', 'pickup_name'], 'give a pickup to a player'],
	'player_set'  : [['player_num', 'variable', 'value'], 'set a variable of a player']
}

# autocompletion
var ac_option_names = G.settings.get_names()
var ac_pickup_names = G.pickups.keys() + ['all'] # (matched case insensitive). 'all' is special and gives all pick-ups at once.
var ac_player_variables = ['health', 'invulnerable']


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

	var scene = get_tree().get_current_scene()

	# these commands only work in-game
	if ['list_players', 'give', 'player_set'].has(cmd):
		if not scene.has_node('Players'):
			log_error('This command can only be used in game.')
			return



	if cmd == 'help':
		var t = []
		for cmd in commands.keys():
			t.append([command_usage(cmd), commands[cmd][1]])
		display_table(t)
	elif cmd == 'clear':
		text.clear()
	elif cmd == 'macro':
		run_macro(args['file'])

	elif cmd == 'exit':
		get_tree().quit()
	elif cmd == 'menu':
		get_tree().change_scene('res://MainMenu/MainMenu.tscn')
	elif cmd == 'reload':
		get_tree().reload_current_scene()
	elif cmd == 'quick_start':
		get_tree().change_scene('res://Utils/QuickStart.tscn')


	elif cmd == 'setop':
		G.settings.set(args['name'], args['value'])
	elif cmd == 'getops':
		var t = []
		t.append(['Name', 'Value', 'Description'])
		for name in G.settings.get_names():
			var v = G.settings.get(name)
			if typeof(v) == TYPE_BOOL:
				v = color_bool(v)
			t.append([name, str(v), G.settings.get_description(name)])
		display_table(t, true, true)
	elif cmd == 'reset_ops':
		G.settings.reset()

	elif cmd == 'players':
		var Players = scene.get_node('Players').get_children()
		var t = []
		t.append(['Num', 'Name', 'Team', 'Control Scheme', 'Health', 'Invulnerable'])
		for p in Players:
			t.append([
				str(p.config.num),
				p.config.name,
				str(p.config.team),
				p.config.get_control_type_string(),
				'%s/%s' % [p.health, p.max_health],
				color_bool(p.invulnerable)
			])
		display_table(t, true, true)

	elif cmd == 'give':
		var player = scene.get_player(int(args['player_num']))
		var name = args['pickup_name']
		if player == null:
			log_error('player %s not found' % args['player_num'])
		elif name != 'all' and not G.pickups.has(name):
			log_error('pickup "%s" not found' % name)
		elif name == 'all':
			for p in G.pickups.values():
				player.equip_weapon(p.scene.instance())
		else:
			player.equip_weapon(G.pickups[name].scene.instance())

	elif cmd == 'player_set':
		var player = scene.get_player(int(args['player_num']))
		if player == null:
			log_error('player %s not found' % args['player_num'])
		var name = args['variable']
		var v = args['value']
		if name == 'health':
			player._set_health(int(v))
		elif name == 'invulnerable':
			player._set_invulnerable(G.cast_from_string(v, TYPE_BOOL))

	else:
		log_error('not implemented')

func run_macro(file):
	var f = File.new()
	var res = f.open(MACRO_DIR + file, f.READ)
	if res != 0:
		print('error %s opening "%s"' % [res, MACRO_DIR + file])
		return
	log_text('<MACRO BEGIN>')
	while not f.eof_reached():
		var l = f.get_line()
		if l != '':
			run(l)
	log_text('<MACRO END>')



func color_bool(v):
	return '[color=%s]%s[/color]' % ['#00ff00' if v else '#ff0000', str(v)]

func set_line(txt):
	line.text = txt
	line.caret_position = len(txt)

func handle_autocomplete():
	var t = line.text
	# test whether the cursor is over or after the last word and only autocomplete if so
	if len(t.right(line.caret_position).split(' ', false)) > 1: # don't allow empty
		return
	var words = t.split(' ', false) # don't allow empty because otherwise double spaces in the middle appear to be words
	if t.ends_with(' '):
		words.append('') # to indicate that the last word has begin, but has nothing yet

	if len(words) > 1: # command already typed
		var cmd = words[0]
		if cmd == 'macro' and len(words) == 2: # autocomplete .macro files in the user directory
			autocomplete_matches(words, utils.listdir(MACRO_DIR))
		if cmd == 'setop' and len(words) == 2: # autocomplete option names
			autocomplete_matches(words, ac_option_names)
		elif cmd == 'give' and len(words) == 3: # autocomplete pickups
			autocomplete_matches(words, ac_pickup_names, false) # not case sensitive
		elif cmd == 'player_set' and len(words) == 3:
			autocomplete_matches(words, ac_player_variables)
	else:
		# command not yet typed: autocomplete commands
		autocomplete_matches(words, commands.keys())



#TODO: if all the matches share a common prefix which is longer than the current prefix: autocomplete as far as possible, eg 'pl' matches [players, player_set] and so should become 'player'
func autocomplete_matches(words, possible_matches, case_sensitive=true):
	var matches = []
	var prefix = '' if words.size() == 0 else (words[-1] if case_sensitive else words[-1].to_lower())
	for item in possible_matches:
		if case_sensitive and item.begins_with(prefix):
				matches.append(item)
		elif not case_sensitive and item.to_lower().begins_with(prefix):
				matches.append(item)

	if len(matches) == 1: # any more or less => can't autocomplete
		var line = ''
		for i in range(words.size() - 1):
			line += words[i] + ' '
		line += matches[0] + ' '
		set_line(line)
	else:
		log_text(str(matches) + '\n')




func move_in_history(history_index):
	var l = len(cmd_history)
	history_index = int(clamp(history_index, -l, 0))
	set_line('' if history_index == 0 else cmd_history[l+history_index])
	return history_index
