extends RigidBody2D

func setup(parent, shot_from):
	parent.add_child(self)

	rotation = shot_from.rotation
	position = shot_from.get_node('ShellEject').global_position
	var shoot_normal = Vector2(0, -1).rotated(shot_from.rotation)
	apply_impulse(Vector2(0, 0), shoot_normal * rand_range(100, 400))
	applied_torque = rand_range(-300, 300)
	
	$DespawnTimer.start()
	$FadeOut.play('FadeOut')


func _on_DespawnTimer_timeout():
	queue_free()
