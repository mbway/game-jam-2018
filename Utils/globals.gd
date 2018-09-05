extends Node

# gamepad axis indices
const JOY_MOVE_X = 0
const JOY_MOVE_Y = 1
const JOY_LOOK_X = 2
const JOY_LOOK_Y = 3
const JOY_DEADZONE = 0.2 # the fraction (0-1) of the axis to ignore from the center



# input methods
const KEYBOARD_CONTROL = 0
const GAMEPAD_CONTROL  = 1
#const NETWORK_CONTROL  = 2 #TODO
const AI_CONTROL       = 3

class PlayerConfig:
	var num # 1-based
	var name # human readable
	var team # 1-based
	var control # CONTROL_TYPE
	var gamepad_id = -1 # only used when control == CONTROL_TYPE.GAMEPAD

	func _init(num=-1, name='', team=-1, control=-1, gamepad_id=-1):
		self.num = num
		self.name = name
		self.team = team
		self.control = control
		self.gamepad_id = gamepad_id

# see _on_StartButton_pressed for how these structures are setup
var game_mode = null # for possible values see Lobby.gd > game_modes
var player_data = [] # list of PlayerConfig
var game_mode_details = {}

# a list of [is_error, message] for the active terminal to pop from and display
var output_queue = []

var settings = null


func log(txt):
	printerr(txt)
	output_queue.append([false, txt])

func log_err(txt):
	print('Error: ' + txt)
	output_queue.append([true, txt])


class Settings:
	extends Node # to use signals
	
	signal settings_changed
	
	var settings_path = null
	var settings_file = null
	# {name : [type, default_value, description]}
	const options = {
		'terminal_enabled' : [TYPE_BOOL, true,  'whether to open a terminal when the ` key is pressed'],
		'full_screen'      : [TYPE_BOOL, false,  'whether the game displays in full screen'],
		'music'            : [TYPE_BOOL, true,  'whether to play music'],
		'mouse_confined'   : [TYPE_BOOL, false, 'whether to prevent the mouse from leaving the window'],
		'free_camera'      : [TYPE_BOOL, false, 'whether the camera is controllable using the arrow keys and scroll wheel (f to toggle following)'],
		'inspect_window'   : [TYPE_BOOL, false, 'whether to display the inspection window'],
		'debug'            : [TYPE_BOOL, false, 'whether the game is in debug mode (has various affects)'],
		'auto_quick_start' : [TYPE_BOOL, false, 'whether to automatically launch QuickStart at startup'],
		'ai_nodes_visible' : [TYPE_BOOL, false, 'whether to draw AI nodes'],
	}

	func _init(settings_path):
		globals.log('settings stored in "%s"' % OS.get_user_data_dir())
		self.settings_path = settings_path
		self.settings_file = ConfigFile.new()
		var err = self.settings_file.load(settings_path)
		if err != OK:
			globals.log_err('could not load user settings: %s' % settings_path)

	func set(name, value):
		if self.options.has(name):
			var type = options[name][0]
			if typeof(value) != type:
				if typeof(value) == TYPE_STRING: # if a string is passed, try to cast it
					value = globals.cast_from_string(value, type)
					if value == null:
						globals.log_err('failed to cast value from string to type<%s>' % type)
						return
				else:
					globals.log_err('invalid type. Expected type<%s>' % type)
					return
			globals.log('saving option: "%s" = %s' % [name, value])
			self.settings_file.set_value('options', name, value)
			self.settings_file.save(self.settings_path)
			self.emit_signal('settings_changed')
		else:
			globals.log_err('unknown option: %s' % name)

	func get(name):
		if self.options.has(name):
			var default_value = self.options[name][1]
			return self.settings_file.get_value('options', name, default_value)
		else:
			globals.log_err('unknown option: %s' % name)
			return null
	
	func get_names():
		return options.keys()
		
	func get_description(name):
		return options[name][2]
	
	func reset():
		for name in get_names():
			self.settings_file.set_value('options', name, options[name][1])
		self.settings_file.save(self.settings_path)
		self.emit_signal('settings_changed')


# returns null if cast unsuccessful, except for where gdscript makes this impossible >:(
func cast_from_string(txt, type):
	if typeof(txt) != TYPE_STRING:
		return null
	if type == TYPE_STRING:
		return txt
	elif type == TYPE_BOOL:
		if txt == 'true' or txt == '1':
			return true
		elif txt == 'false' or txt == '0':
			return false
		else:
			return null
	elif type == TYPE_INT:
		return int(txt) # returns 0 if cannot convert :(
	elif type == TYPE_REAL:
		return float(txt) # returns 0 if cannot convert :(


func _ready():
	settings = Settings.new('user://settings.cfg')
