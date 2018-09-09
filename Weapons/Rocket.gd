extends RigidBody2D

export (PackedScene) var bullet_scene = preload('res://Weapons/Explosion.tscn')

const MAX_DISTANCE = 10000 # despawn after this distance

onready var Math = preload('res://Utils/Math.gd')

# set on setup
var is_setup = false
var shot_from
var speed
var spawn_loc
var shoot_direction
var damage
var bullet_parent


func setup(parent, shot_from, speed, damage):
	self.shot_from = shot_from
	self.speed = speed
	self.damage = damage
	self.bullet_parent = parent
	
	parent.add_child(self)

	rotation = shot_from.rotation
	position = shot_from.get_node('Muzzle').global_position
	spawn_loc = global_position
	#var spread = rand_range(-shot_from.spread, shot_from.spread)
	var spread = Math.random_normal(0, shot_from.spread)
	shoot_direction = Vector2(1, 0).rotated(shot_from.rotation + spread)
	
	is_setup = true

func add_collision_exception(body):
	add_collision_exception_with(body)

# before godot 3, used to be called _fixed_process
func _physics_process(delta):
	if is_setup:
		if global_position.distance_to(spawn_loc) > MAX_DISTANCE:
			queue_free()
		position += shoot_direction * speed * delta

func _on_Rocket_body_entered(body):
	var explosion = bullet_scene.instance()
	explosion.setup(global_position, damage)
	bullet_parent.add_child(explosion)
	queue_free()
