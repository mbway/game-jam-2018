extends Area2D

signal flag_returned_1
signal flag_returned_2

#TODO: fix by using groups instead
const player_scene_path = 'res://Player.tscn'
const flag_scene_path = 'res://Objects/Flag.tscn'


export (int) var team = 0
export (String) var colour = 'red'

func _process(delta):
	$Sprite.play(colour)

func _on_Base_area_entered(body):
	if body.get_filename() == flag_scene_path:
		if self.team != body.team:
			$CapturedSound.play()
			emit_signal('flag_returned_' + str(team))
