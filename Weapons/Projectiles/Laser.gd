extends Area2D

# set on setup
var shot_from: Gun
var player: Player
var damage: float

func setup(player, parent, shot_from, vel, damage):
	self.shot_from = shot_from
	self.player = player
	self.damage = damage
	
	parent.add_child(self)
	
	rotation = shot_from.rotation
	position = shot_from.get_node('Muzzle').global_position
	
	$Lifetime.start()
	$AnimationPlayer.play('FadeOut')

func _on_Laser_body_entered(body):
	if body == player.get_node('BulletCollider'): # don't collide with the player who fired the laser
		return
	if body.is_in_group('damageable'):
		body.take_damage(damage, Vector2(0, 0))

func _on_Lifetime_timeout():
	queue_free()
