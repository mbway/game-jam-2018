extends RigidBody2D

onready var Math = preload('res://Utils/Math.gd')

# set on setup
var is_setup = false
var shot_from
var spawn_loc
var shoot_direction


func setup(parent, shot_from):
	self.shot_from = shot_from
	
	parent.add_child(self)

	rotation = shot_from.rotation
	position = shot_from.get_node('ShellEject').global_position
	spawn_loc = global_position
	#var spread = rand_range(-shot_from.spread, shot_from.spread)
	var spread = Math.random_normal(0, 1)
	shoot_direction = Vector2(-1000, -1000).rotated(shot_from.rotation + spread)
	linear_velocity = shoot_direction
	angular_velocity = 1
	
	$DespawnTimer.start()
	
	is_setup = true


func _on_DespawnTimer_timeout():
	queue_free()
