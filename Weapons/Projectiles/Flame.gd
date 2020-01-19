extends 'res://Weapons/Projectiles/Projectile.gd'

func setup(player, parent, shot_from, speed, damage):
	.setup(player, parent, shot_from, speed, damage)
	set_axis_velocity(linear_velocity) # let the physics engine handle movement

func get_knockback(body):
	return Vector2(0, 0)

func _on_body_entered(body):
	if body.is_in_group('damageable'):
		body.take_damage(damage, get_knockback(body))
	# don't despawn

func _on_DespawnTimer_timeout():
	queue_free()
