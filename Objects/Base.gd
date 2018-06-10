extends Area2D

signal flag_returned_1
signal flag_returned_2

const player_scene_path = 'res://Player.tscn'
const flag_scene_path = 'res://Flag.tscn'


export (int) var team = 0

func _on_Base_area_entered(body):
	if body.get_filename() == flag_scene_path:
		if self.team != body.team:
			emit_signal('flag_returned_' + str(team))