extends Node

# for debugging purposes, this script can be used to jump right into a game without using the main menu

var globals

func _ready():
	globals = get_node('/root/globals')
	
	globals.player_data = [
		globals.PlayerData.new(1, 'Player 1', 1, globals.KEYBOARD_CONTROL),
		globals.PlayerData.new(2, 'Player 2', 2, globals.GAMEPAD_CONTROL, 0),
		globals.PlayerData.new(2, 'Player 3', 2, globals.AI_CONTROL)
	]
	