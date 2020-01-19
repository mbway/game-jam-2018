extends RigidBody2D
class_name Projectile

const MAX_DISTANCE_SQ := 1.0 * 10000 * 10000 # despawn after this distance

var spawn_pos: Vector2
var damage: float

# player: the player holding the weapon which fired this projectile
# parent: the container node to add this projectile as a child of
# shot_from: the weapon which fired this projectile
func setup(player, parent: Node2D, shot_from, speed: float, set_damage: float):
	self.damage = set_damage

	parent.add_child(self)
	# won't collide with player directly because it is on a different layer
	add_collision_exception_with(player.get_node('BulletCollider'))

	rotation = shot_from.rotation
	global_position = shot_from.get_node('Muzzle').global_position
	spawn_pos = global_position
	var spread := Math.random_normal(0.0, shot_from.spread)
	linear_velocity = Vector2(1, 0).rotated(shot_from.rotation + spread) * speed

func _process(delta: float):  # override
	if global_position.distance_squared_to(spawn_pos) > MAX_DISTANCE_SQ:
		queue_free()

func get_knockback(_body: PhysicsBody2D) -> Vector2:
	return linear_velocity / 20

func _on_body_entered(body: PhysicsBody2D):  # override
	if body.is_in_group('damageable'):
		body.take_damage(damage, get_knockback(body))
	queue_free()
