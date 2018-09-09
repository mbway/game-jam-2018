extends 'res://Weapons/Projectiles/Projectile.gd'

var Explosion = preload('res://Weapons/Explosion.tscn')

func _on_body_entered(body):
	var explosion = Explosion.instance()
	explosion.setup(global_position, damage)
	get_parent().add_child(explosion)
	queue_free()