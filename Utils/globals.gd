extends Node

# use to enable things that should only happen during development
const DEBUG = true

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
var game_mode = null
var player_data = [] # list of PlayerConfig
var game_mode_details = {}

const SETTINGS_PATH = 'user://settings.cfg'
var settings

func _ready():
	print('settings stored at "%s"' % OS.get_user_data_dir())
	settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		print('could not load user settings: %s' % SETTINGS_PATH)
