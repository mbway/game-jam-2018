extends Node

func _ready():
	var gun_scene = load('res://Weapons/MachineGun.tscn')
	$Player.setup('p1_', 100, $Bullets, $Camera, true)
	$Player.equip(gun_scene.instance())
	
	
	var input = load('res://input.gd').new()
	input.list_maps('test')
	input.clear_input_maps()
	input.assign_keyboard_mouse_input('p1_')
	#input.assign_gamepad_input('p1_')

