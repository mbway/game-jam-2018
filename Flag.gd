extends Area2D

signal flag_returned

const player_scene_path = 'res://Player.tscn'
const base_scene_path = 'res://Base.tscn'

export (int) var homeX = 0
export (int) var homeY = 0

export (int) var team = 0

export (String) var colour

var target = null

func _ready():
	reset()

func _process(delta):
	$Sprite.play(colour)
	if target:
		position = target.position
		

func reset():
	position.x = homeX
	position.y = homeY
	target = null


func _on_Flag_body_entered(body):
	if body.get_filename() == player_scene_path:
		target = body
		


func _on_Flag_area_entered(area):
	if area.get_filename() == base_scene_path:
		reset()
