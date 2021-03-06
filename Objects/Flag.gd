extends Area2D

signal flag_returned

const player_scene_path = 'res://Player.tscn'
const base_scene_path = 'res://Objects/Base.tscn'

var homeX = 0
var homeY = 0

export (int) var team = 0

export (String) var colour

var target = null

#TODO: parent to the player which picks it up rather than manually tracking position
#TODO: give some movement like slightly swaying when not held.
#TODO: possibly apply a constant rotation while being held.

func _ready():
	homeX = position.x
	homeY = position.y

func _process(delta):
	$Sprite.play(colour)
	if target and target.alive:
		position.x = target.position.x
		position.y = target.position.y - 32
	else:
		reset()
		target = null
		

func reset():
	position.x = homeX
	position.y = homeY
	target = null


func _on_Flag_body_entered(body):
	if !target and body.get_filename() == player_scene_path:
		if body.team == self.team:
			reset()
		else:
			target = body
		


func _on_Flag_area_entered(area):
	if area.get_filename() == base_scene_path and area.team != self.team:
		reset()
