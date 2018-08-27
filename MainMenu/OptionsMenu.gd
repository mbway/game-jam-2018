extends Control


signal settings_changed
signal back

onready var G = globals


# more options ideas
# - fullscreen
# - enable / disable gamepad rumble
# - whether to capture mouse (prevent leaving the window)

class BoolOption:
	extends Node # required for using connect
	var option_name
	var checkbox
	var op

	func _init(op, checkbox, option_name):
		self.op = op
		self.checkbox = checkbox
		self.option_name = option_name
		self.checkbox.pressed = globals.settings.get(self.option_name)
		self.checkbox.connect('toggled', self, '_on_toggled', [])

	func _on_toggled(pressed):
		globals.settings.set(self.option_name, pressed)
		self.op.emit_signal('settings_changed')


func _ready():
	var music_checkbox = BoolOption.new(self, find_node('Music'), 'music')
	var confined_checkbox = BoolOption.new(self, find_node('Confine'), 'mouse_confined')
	var terminal_checkbox = BoolOption.new(self, find_node('Terminal'), 'terminal_enabled')

func _process(delta):
	$Background.region_rect.position.x += delta * 800
	$Background.region_rect.position.y -= delta * 50

func _on_BackButton_pressed():
	emit_signal('back')
