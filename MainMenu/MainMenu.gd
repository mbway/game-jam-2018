extends Node

onready var G = globals
onready var start_screen_scene = preload('res://MainMenu/StartScreen.tscn')
onready var options_screen_scene = preload('res://MainMenu/OptionsMenu.tscn')
onready var lobby_screen_scene = preload('res://MainMenu/Lobby.tscn')

#note: for the menus to render at the correct resolution, the min_size has to be set on the root control node for the menu.


func _ready():
	randomize() # generate true random numbers
	_on_settings_changed()
	G.settings.connect('settings_changed', self, '_on_settings_changed')
	
	if G.settings.get('auto_quick_start'):
		get_tree().change_scene('res://Utils/QuickStart.tscn')
	
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
	if G.settings.get('music'):
		$Music.play()
	else:
		$Music.stop()
	
	var term_enabled = G.settings.get('terminal_enabled')
	if term_enabled and not has_node('Terminal'):
		add_child(preload('res://UI/Terminal.tscn').instance())
	elif not term_enabled and has_node('Terminal'):
		$Terminal.queue_free()
	
	OS.set_window_fullscreen(G.settings.get('full_screen'))

