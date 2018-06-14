extends CanvasLayer

func _ready():
	$Message.hide()
	$GameOver.hide()

func connect_player(player, player_num):
	var slots = null
	if player_num == 1:
		slots = $P1WeaponSlots
	elif player_num == 2:
		slots = $P2WeaponSlots
	else:
		print('only 2 weapon slots supported')
		return
	player.connect('weapon_equiped', slots, '_on_Player_weapon_equiped')
	player.connect('weapon_selected', slots, '_on_Player_weapon_selected')
	
func set_score_labels(L, R):
	$P1Score.text = L
	$P2Score.text = R

func show_game_over(winner):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$GameOver/GameOverMessage.text = 'Game Over!\n%s Wins' % winner
	$GameOver.show()

func _input(event):
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