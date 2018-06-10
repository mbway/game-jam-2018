extends Area2D

signal flag_returned

const player_scene_path = 'res://Player.tscn'
const flag_scene_path = 'res://Flag.tscn'

export (int) var homeX = 0
export (int) var homeY = 0

export (int) var team = 0


var target

func _ready():
	reset()


func reset():
	position.x = homeX
	position.y = homeY


func _on_Base_body_entered(body):
	if body.get_filename() == flag_scene_path:
		print('test')
