extends Node

onready var start_screen_scene = preload('res://MainMenu/StartScreen.tscn')
onready var options_screen_scene = preload('res://MainMenu/OptionsMenu.tscn')
onready var lobby_screen_scene = preload('res://MainMenu/Lobby.tscn')


func _ready():
	randomize() # generate true random numbers
	if globals.settings.get_value('options', 'music', true):
		$Music.play()
	
	# Input.set_custom_mouse_cursor(preload('res://Assets/cursor.png'), Input.CURSOR_ARROW, Vector2(2, 2))
	
	# if captured, returns the mouse to normal. Also resets the custom cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	show_start_screen()

func show_start_screen():
	change_screen(start_screen_scene)
	$Screen.connect('start', self, 'show_lobby_screen')
	$Screen.connect('options', self, 'show_options_screen')
	
func show_options_screen():
	change_screen(options_screen_scene)
	$Screen.connect('back', self, 'show_start_screen')
	$Screen.connect('settings_changed', self, '_on_settings_changed')

func show_lobby_screen():
	change_screen(lobby_screen_scene)
	$Screen.connect('back', self, 'show_start_screen')



func change_screen(screen_scene):
	if has_node('Screen'):
		var old_screen = $Screen
		remove_child(old_screen)
		old_screen.queue_free()
	var screen = screen_scene.instance()
	screen.name = 'Screen'
	add_child(screen)

func _on_settings_changed():
	if globals.settings.get_value('options', 'music', true):
		$Music.play()
	else:
		$Music.stop()
