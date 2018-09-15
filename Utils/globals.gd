extends Node

# gamepad axis indices
enum JoyAxis {
	MOVE_X = 0
	MOVE_Y = 1
	LOOK_X = 2
	LOOK_Y = 3
}
const JOY_DEADZONE = 0.2 # the fraction (0-1) of the axis to ignore from the center


# input methods
enum Control {
	KEYBOARD = 0
	GAMEPAD  = 1
	#const NETWORK = 2 #TODO
	AI       = 3
}

class PlayerConfig:
	var num # 1-based
	var name # human readable
	var team # 1-based
	var control # Control
	var gamepad_id = -1 # only used when control == Control.GAMEPAD

	func _init(num=-1, name='', team=-1, control=-1, gamepad_id=-1):
		self.num = num
		self.name = name
		self.team = team
		self.control = control
		self.gamepad_id = gamepad_id

	func get_control_type_string():
		if control == Control.KEYBOARD:
			return 'Keyboard'
		elif control == Control.GAMEPAD:
			return 'Gamepad_%s' % gamepad_id
		elif control == Control.AI:
			return 'AI'
		else:
			return 'Invalid'


# see _on_StartButton_pressed for how these structures are setup
var game_mode = null # for possible values see Lobby.gd > game_modes
var player_data = [] # list of PlayerConfig
var game_mode_details = {}

# a list of [is_error, message] for the active terminal to pop from and display
var output_queue = []

var settings = null

# these are elements of a bitmask and can be bitwise OR'd together
enum Layers {
	PLAYERS                = 1,
	MAP                    = 2,
	BULLET_COLLIDERS       = 4,
	COLLIDABLE_PROJECTILES = 8
}

# All the available weapons and pickups and their textures
# preload everything because it will have to be loaded at some point anyway.
var pickups = {
	'Pistol': {
		'scene':   preload('res://Weapons/Pistol.tscn'),
		'texture': preload('res://Assets/weapons/pistol.png')},
	'LaserCannon': {
		'scene':   preload('res://Weapons/LaserCannon.tscn'),
		'texture': preload('res://Assets/weapons/laserCannon.png')},
	'MachineGun': {
		'scene':   preload('res://Weapons/MachineGun.tscn'),
		'texture': preload('res://Assets/weapons/machinegun.png')},
	'Minigun': {
		'scene':   preload('res://Weapons/Minigun.tscn'),
		'texture': preload('res://Assets/weapons/Minigun/minigun1.png')},
	'Shotgun': {
		'scene':   preload('res://Weapons/Shotgun.tscn'),
		'texture': preload('res://Assets/weapons/Shotgun/shotgun1.png')},
	'Sniper': {
		'scene':   preload('res://Weapons/Sniper.tscn'),
		'texture': preload('res://Assets/weapons/sniper.png')},
	'FlameThrower': {
		'scene':   preload('res://Weapons/FlameThrower.tscn'),
		'texture': preload('res://Assets/weapons/flamethrower.png')},
	'Revolver': {
		'scene':   preload('res://Weapons/Revolver.tscn'),
		'texture': preload('res://Assets/weapons/revolver/Revolver.png')},
	'TommyGun': {
		'scene':   preload('res://Weapons/TommyGun.tscn'),
		'texture': preload('res://Assets/weapons/tommyGun.png')},
	'GrenadeLauncher': {
		'scene':   preload('res://Weapons/GrenadeLauncher.tscn'),
		'texture': preload('res://Assets/weapons/Grenade Launcher/GrenadeLauncher1.png')},
	'RocketLauncher': {
		'scene':   preload('res://Weapons/RocketLauncher.tscn'),
		'texture': preload('res://Assets/weapons/rocketlauncher_new.png')},
	'ClassicRocketLauncher': {
		'scene':   preload('res://Weapons/ClassicRocketLauncher.tscn'),
		'texture': preload('res://Assets/weapons/rocketlauncher.png')},
	'MineLauncher': {
		'scene':   preload('res://Weapons/MineLauncher.tscn'),
		'texture': preload('res://Assets/weapons/Mine Launcher/Mine Launcher1.png')},
}

func log(txt):
	printerr(txt)
	output_queue.append([false, txt])

func log_err(txt):
	print('Error: ' + txt)
	output_queue.append([true, txt])

func get_scene():
	return get_tree().get_current_scene()


#TODO: break out into Settings.gd
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
		'camera_shake'     : [TYPE_BOOL, true,  'whether the camera shakes in response to events in the game (like firing a weapon)'],
		'inspect_window'   : [TYPE_BOOL, false, 'whether to display the inspection window'],
		'debug'            : [TYPE_BOOL, false, 'whether the game is in debug mode (has various affects)'],
		'auto_quick_start' : [TYPE_BOOL, false, 'whether to automatically launch QuickStart at startup (bypassing the main menu)'],
		'ai_nodes_visible' : [TYPE_BOOL, false, 'whether to draw AI nodes'],
		'nav_visible'      : [TYPE_BOOL, false, 'whether to draw the navigation graph'],
		'game_speed'       : [TYPE_REAL, 1.0,   'the game play speed (1.0 for normal, 0.5 for half speed etc)'],
		'mute_all'         : [TYPE_BOOL, false, 'whether to prevent the game from producing any sound'],
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
