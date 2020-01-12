extends CanvasLayer

func _ready():
	$Message.hide()
	$GameOver.hide()
	$CenterLabel.hide()

func connect_player(player: Player, player_num: int):
	var slots = null
	if player_num == 1:
		slots = $P1WeaponSlots
	elif player_num == 2:
		slots = $P2WeaponSlots
	else:
		print('only 2 weapon slots supported')
		return
	player.inventory.connect('equiped', slots, '_on_equiped')
	player.inventory.connect('unequiped', slots, '_on_unequiped')
	player.inventory.connect('selected', slots, '_on_selected')

func set_score_labels(L: String, R: String):
	$P1Score.text = L
	$P2Score.text = R

func hide_score_labels() -> void:
	$P1Score.hide()
	$P2Score.hide()

func set_center_label(text: String) -> void:
	$CenterLabel.text = text

func show_center_label() -> void:
	$CenterLabel.show()

func show_game_over(message):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$GameOver/GameOverMessage.text = 'Game Over!\n%s' % message
	$GameOver.show()

func _gui_input(event):
	if $GameOver.visible:
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == 16: # XBOX button
				_on_MainMenu_pressed()

func show_message(text):
	$Message.text = text
	$Message.show()
	$Message/Timeout.start()

func _on_Timeout_timeout():
	$Message.hide()

func _on_MainMenu_pressed():
	get_tree().change_scene('res://MainMenu/MainMenu.tscn')
