extends Node

func _ready():
	var pistol_scene = load('res://Weapons/Pistol.tscn')
	$Player.setup('p1_', $Bullets, $Camera, true)
	$Player.equip(pistol_scene.instance())
	
	$Player2.setup('p2_', $Bullets, $Camera, false)
	$Player2.equip(pistol_scene.instance())
	
	var input = load('res://input.gd').new()
	input.clear_input_maps()
	input.assign_keyboard_mouse_input('p1_')
	input.assign_gamepad_input('p2_')




