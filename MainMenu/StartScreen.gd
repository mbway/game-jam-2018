extends Control

signal start
signal options

func _on_Exit_pressed():
	get_tree().quit()

func _on_Start_pressed():
	emit_signal('start')

func _on_Options_pressed():
	emit_signal('options')

func _process(delta):
	$Background.region_rect.position.x += delta * 1500
	$Background.region_rect.position.y -= delta * 50

