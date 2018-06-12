extends Control

signal game_chosen(details)

var game_mode = null

func _on_TDMButton_pressed():
	game_mode = 'TDM'
	show_select_map()

func _on_CTFButton_pressed():
	game_mode = 'CTF'
	show_select_map()

func _on_OverruleButton_pressed():
	game_mode = 'Overrule'
	show_select_map()

func show_select_map():
	$MapMenu.map_type = game_mode
	$MapMenu.change_selection(1)
	
	$ModeMenu.hide()
	$MapMenu.show()
	
func _process(delta):
	$Background.region_rect.position.x += delta * 1500
	$Background.region_rect.position.y -= delta * 50

func _on_Select_pressed():
	emit_signal('game_chosen', {'map_path':$MapMenu.get_map_path(), 'game_mode':game_mode})