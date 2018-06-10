extends Node

onready var input = load('res://input.gd').new()

var local_multiplayer = true # not currently determined through UI
var game_mode = null



func _ready():
	randomize() # generate true random numbers

	input.clear_input_maps()


func start_local_multiplayer():
	$MainMenu.hide()
	
	input.assign_keyboard_mouse_input('p1_')
	input.assign_gamepad_input('p2_')
	
	var map = $MainMenu/MapMenu.create_map()
	map.name = 'World'
	add_child(map)


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
	$MainMenu/ModeMenu.hide()
	$MainMenu/MapMenu.show()


func _on_Select_pressed():
	start_local_multiplayer()
