extends Node

func _ready():
	var pistol_scene = load('res://Weapons/Pistol.tscn')
	$Player.setup('p1_', $Bullets, null)#$Camera)
	$Player.equip(pistol_scene.instance())
	
	var input = load('res://input.gd').new()
	input.clear_input_maps()
	input.assign_keyboard_mouse_input('p1_')




