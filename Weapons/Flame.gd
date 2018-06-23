extends RigidBody2D

const MAX_DISTANCE = 10000 # despawn after this distance

onready var Math = preload('res://Utils/Math.gd')

# set on setup
var is_setup = false
var shot_from
var speed
var spawn_loc
var shoot_direction
var damage


func setup(parent, shot_from, speed, damage):
	self.shot_from = shot_from
	self.speed = speed
	self.damage = damage
	
	parent.add_child(self)

	rotation = shot_from.rotation
	position = shot_from.get_node('Muzzle').global_position
	spawn_loc = global_position
	#var spread = rand_range(-shot_from.spread, shot_from.spread)
	var spread = Math.random_normal(0, shot_from.spread)
	shoot_direction = Vector2(1, 0).rotated(shot_from.rotation + spread)
	
	set_axis_velocity(shoot_direction * speed)
	
	is_setup = true


func add_collision_exception(body):
	add_collision_exception_with(body)


func _on_Bullet_body_entered(body):
	if body.is_in_group('damageable'):
		body.take_damage(damage)
	

func _on_DespawnTimer_timeout():
	queue_free()
