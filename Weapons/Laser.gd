extends Area2D

const player_scene_path = 'res://Player.tscn'
const orb_scene_path = 'res://Objects/Orb.tscn'

# set on setup
var shot_from
var damage

func setup(parent, shot_from, vel, damage):
	self.shot_from = shot_from
	self.damage = damage
	
	parent.add_child(self)
	
	rotation = shot_from.rotation
	position = shot_from.get_node('Muzzle').global_position
	
	$Lifetime.start()
	$AnimationPlayer.play('FadeOut')


func _on_Laser_body_entered(body):
	# only deal damage to other playersd
	var hit_other_player = bool(body.get_filename() == player_scene_path and body != shot_from.get_node('../..'))
	var hit_orb = body.get_filename() == orb_scene_path
	if hit_other_player or hit_orb:
		body.take_damage(damage)

func _on_Lifetime_timeout():
	queue_free()