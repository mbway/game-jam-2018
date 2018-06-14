extends Area2D

const player_scene_path = 'res://Player.tscn'
const orb_scene_path = 'res://Objects/Orb.tscn'

# set on setup
var shot_from
var collision_exceptions = []
var damage

func setup(parent, shot_from, vel, damage):
	self.shot_from = shot_from
	self.damage = damage
	
	parent.add_child(self)
	
	rotation = shot_from.rotation
	position = shot_from.get_node('Muzzle').global_position
	
	$Lifetime.start()
	$AnimationPlayer.play('FadeOut')

func add_collision_exception(body):
	collision_exceptions.append(body)

func _on_Laser_body_entered(body):
	for b in collision_exceptions:
		if body == b:
			return
	
	if body.get_filename() == orb_scene_path:
		body.take_damage(damage)
		
	# will collide with the bullet collider, the player is its parent
	var parent = body.get_node('..')
	if parent.get_filename() == player_scene_path:
		parent.take_damage(damage)
	

func _on_Lifetime_timeout():
	queue_free()