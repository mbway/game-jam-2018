extends Control

func _on_HostButton_pressed():
	$Net.host_game($Panel/Username.text)
	$Panel.hide()
	$Lobby.show()


func _on_JoinButton_pressed():
	$Net.join_game($Panel/IP.text, $Panel/Username.text)
	$Panel.hide()
	$Lobby.show()


func _on_Net_player_registered(id):
	print(id)
	$Lobby/ItemList.add_item(str(id))
