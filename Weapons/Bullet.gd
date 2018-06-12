extends RigidBody2D

const MAX_DISTANCE = 10000 # despawn after this distance
const player_scene_path = 'res://Player.tscn'
const orb_scene_path = 'res://Objects/Orb.tscn'

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
	var spread = rand_range(-shot_from.spread, shot_from.spread)
	shoot_direction = Vector2(1, 0).rotated(shot_from.rotation + spread)
	
	is_setup = true

# before godot 3, used to be called _fixed_process
func _physics_process(delta):
	if is_setup:
		if global_position.distance_to(spawn_loc) > MAX_DISTANCE:
			queue_free()
		position += shoot_direction * speed * delta


func _on_Bullet_body_entered(body):
	# only deal damage to other players
	var hit_other_player = bool(body.get_filename() == player_scene_path and body != shot_from.get_node('../..'))
	var hit_orb = body.get_filename() == orb_scene_path
	if hit_other_player or hit_orb:
		body.take_damage(damage)
	queue_free()
