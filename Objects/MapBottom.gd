extends Node2D

const player_scene_path = 'res://Player.tscn'

func _on_Area2D_body_entered(body):
	if body.get_filename() == player_scene_path:
		body.die()
