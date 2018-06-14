extends Control

signal settings_changed
signal back

var globals

var music_checkbox

# more options ideas
# - fullscreen
# - enable / disable gamepad rumble
# - whether to capture mouse (prevent leaving the window)

func _ready():
	globals = get_node('/root/globals')
	music_checkbox = find_node('Music')
	var music = globals.settings.get_value('options', 'music', true) # default = true
	music_checkbox.pressed = music

func _process(delta):
	$Background.region_rect.position.x += delta * 800
	$Background.region_rect.position.y -= delta * 50

func _on_BackButton_pressed():
	emit_signal('back')
	

func save_settings():
	globals.settings.save(globals.SETTINGS_PATH)
	emit_signal('settings_changed')

func _on_Music_toggled(button_pressed):
	globals.settings.set_value('options', 'music', button_pressed)
	save_settings()

func _on_Confine_toggled(button_pressed):
	globals.settings.set_value('options', 'mouse_confined', button_pressed)
	save_settings()
