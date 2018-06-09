extends Camera2D

export (NodePath) var follow_path
onready var follow = get_node(follow_path)

func _physics_process(delta):
	set_global_position(follow.global_position)
