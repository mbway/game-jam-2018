extends Node

func _ready():
	var pistol_scene = load('res://Weapons/Pistol.tscn')
	$Player.setup($Bullets, 'fire', $Camera)
	$Player.equip(pistol_scene)

