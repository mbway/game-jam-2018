extends Node


func _ready():
	var pistol_scene = load('res://Weapons/Pistol.tscn')
	$Player.setup($Bullets, 'fire', $Camera2D)
	$Player.equip(pistol_scene)
