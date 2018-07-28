extends Area2D

var damage
var radius = 30

func setup(pos, damage):
	position = pos
	self.damage = damage

func _on_DespawnTimer_timeout():
	queue_free()

func _on_Explosion_body_entered(body):
	if body.is_in_group('damageable'):
		var distance = position.distance_to(body.position)
		var force_scale = distance/radius
		body.take_damage(damage * force_scale)
		body.velocity.x += 100
		body.velocity.y -= 100
