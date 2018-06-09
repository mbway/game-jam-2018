extends RigidBody2D

const MAX_DISTANCE = 1000

var shot_from
var vel

var spawn_loc
var shoot_direction

func _ready():
	pass

func setup(shot_from, vel):
	self.shot_from = shot_from
	self.vel = vel
	
	# can't use self.get_node because may not be ready/added to the tree yet
	var parent = shot_from.get_node('/root/Main/Bullets')
	parent.add_child(self)
	
	position = shot_from.get_node('Muzzle').global_position
	spawn_loc = global_position
	shoot_direction = Vector2(1, 0).rotated(shot_from.rotation)
	#set_z_index(0)
	
	#print('bullet setup')


# before godot 3, used to be called _fixed_process
func _physics_process(delta):
	if global_position.distance_to(spawn_loc) > MAX_DISTANCE:
		kill()
	
	position += shoot_direction * vel * delta


func kill():
	print('deleted')
	hide()
	queue_free()


func _on_Bullet_body_entered(body):
	print(body)
	kill()
