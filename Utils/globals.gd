extends Node

# see _on_StartButton_pressed for how these structures are setup
var game_mode = null
var player_data = []
var game_mode_details = {}

const SETTINGS_PATH = 'user://settings.cfg'
var settings

func _ready():
	print('settings stored at "%s"' % OS.get_user_data_dir())
	settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		print('could not load user settings: %s' % SETTINGS_PATH)