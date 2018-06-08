extends RigidBody2D

const MAX_DISTANCE = 1000

var travelled = 0
var shot_from = None
var spawn_loc = None
var parent = None

func _ready():
	pass

func setup(shot_from):
	.shot_from = shot_from
	spawn_loc = global_position
	parent = get_node('/root/Bullets')
	parent.add_child(self)
	position = shot_from.get_node('Muzzle').position
	set_z(0)
	connect('body_entered', self, 'kill')

# _fixed_process is synced to physics
func _fixed_process(delta):
	travelled += global_position.distance_to(spawn_loc)
	if travelled > MAX_DISTANCE:
		kill()


func kill():
	queue_free()
