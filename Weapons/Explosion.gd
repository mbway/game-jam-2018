extends Area2D

var damage
onready var radius = $Collision.shape.radius

func _init():
	monitoring = false # don't detect collisions until setup

func setup(pos, damage):
	position = pos
	self.damage = damage
	monitoring = true
	if find_node('ExplosionAnimation'):
		$ExplosionAnimation.frame = 0
		$ExplosionAnimation.play()

func _on_DespawnTimer_timeout():
	queue_free()

func _on_CollisionTimer_timeout():
	monitoring = false

func _on_Explosion_body_entered(body):
	if body.is_in_group('damageable'):
		# slightly lower the center to encourage upwards velocity
		var v = (body.global_position - Vector2(0, 10)) - global_position
		var knockback = v.normalized() * 1000

		var dd = globals.get_scene().debug_draw
		dd.add_vector(v, position, 5)

		body.take_damage(damage, knockback)


