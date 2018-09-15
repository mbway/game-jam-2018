extends 'res://Weapons/Projectiles/Projectile.gd'

export (PackedScene) var Explosion = preload('res://Weapons/Explosion.tscn')

var detonating = false

func _on_body_entered(body):
	if !body.is_in_group('damageable'):
		self.velocity = Vector2(0, 0)
		self.rotation = 0
		


func _on_Detection_body_entered(body):
	if !detonating and body.is_in_group('damageable'):
		$DetonationTimer.start()
		$Sprite.play('Explode')
		$ActivationSound.play()
		detonating = true


func _on_DetonationTimer_timeout():
	var explosion = Explosion.instance()
	explosion.setup(global_position, damage)
	get_parent().add_child(explosion)
	queue_free()
