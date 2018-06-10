extends Area2D

const player_scene_path = 'res://Player.tscn'

export (int) var homeX = 0
export (int) var homeY = 0

export (String) var colour

var target

func _ready():
	pass

func _process(delta):
	
	$Sprite.play(colour)
	if target:
		position = target.position
	


func _on_Flag_body_entered(body):
	if body.get_filename() == player_scene_path:
		target = body
	
