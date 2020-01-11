extends RigidBody2D

const MAX_DISTANCE_SQ := 1.0 * 10000 * 10000 # despawn after this distance
onready var Math = preload('res://Utils/Math.gd')

var spawn_pos: Vector2
var velocity: Vector2
var damage: float

func _init():  # override
	set_physics_process(false) # don't process physics until set up

# player: the player holding the weapon which fired this projectile
# parent: the container node to add this projectile as a child of
# shot_from: the weapon which fired this projectile
func setup(player, parent, shot_from, speed: float, set_damage: float):
	self.damage = set_damage

	parent.add_child(self)
	# won't collide with player directly because it is on a different layer
	add_collision_exception_with(player.get_node('BulletCollider'))

	rotation = shot_from.rotation
	global_position = shot_from.get_node('Muzzle').global_position
	spawn_pos = global_position
	var spread = Math.random_normal(0, shot_from.spread)
	velocity = Vector2(1, 0).rotated(shot_from.rotation + spread) * speed
	set_physics_process(true)

func _physics_process(delta: float):  # override
	if global_position.distance_squared_to(spawn_pos) > MAX_DISTANCE_SQ:
		queue_free()
	# a note about the continuous collision detection: the shape or ray seems to
	# be cast between the last 2 positions, so if the position is not modified
	# since teleporting from 0,0 to the spawn location, the bullet will probably
	# appear to have teleported through the map and immediately de spawn. Even
	# `position += Vector2(0, 0)` can be used to avoid this.
	position += velocity * delta

func get_knockback(_body: PhysicsBody2D) -> Vector2:
	return velocity / 20

func _on_body_entered(body: PhysicsBody2D):  # override
	if body.is_in_group('damageable'):
		body.take_damage(damage, get_knockback(body))
	queue_free()
