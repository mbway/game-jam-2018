extends Projectile

export (PackedScene) var Explosion = preload('res://Weapons/Explosion.tscn')

var detonating := false

func _on_body_entered(body: PhysicsBody2D):  # override
	if !body.is_in_group('damageable'):
		self.linear_velocity *= 0.2
		self.rotation = 0.0


func _on_Detection_body_entered(body: PhysicsBody2D):
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
