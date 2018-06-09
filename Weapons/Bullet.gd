extends RigidBody2D

const MAX_DISTANCE = 1000
const player_scene_path = 'res://Player.tscn'

# set on setup
var shot_from
var vel
var spawn_loc
var shoot_direction
var damage


func setup(parent, shot_from, vel, damage):
	self.shot_from = shot_from
	self.vel = vel
	self.damage = damage
	
	rotation = shot_from.rotation
	
	# can't use self.get_node because may not be ready/added to the tree yet
	#var parent = shot_from.get_node(parent_path)
	#print(parent_path)
	parent.add_child(self)
	
	position = shot_from.get_node('Muzzle').global_position
	spawn_loc = global_position
	shoot_direction = Vector2(1, 0).rotated(shot_from.rotation)


# before godot 3, used to be called _fixed_process
func _physics_process(delta):
	if global_position.distance_to(spawn_loc) > MAX_DISTANCE:
		queue_free()
	position += shoot_direction * vel * delta


func _on_Bullet_body_entered(body):
	if body.get_filename() == player_scene_path:
		body.take_damage(damage)
	queue_free()
