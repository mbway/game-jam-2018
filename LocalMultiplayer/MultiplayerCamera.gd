extends Camera2D

export (Array, NodePath) var follow_paths
var follow

func _ready():
	follow = []
	for f in follow_paths:
		follow.append(get_node(f))
	print(follow)

func _physics_process(delta):
	set_global_position(follow[0].global_position)
