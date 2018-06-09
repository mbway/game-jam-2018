extends Camera2D

export (Array, NodePath) var follow_paths = []
var follow

func _ready():
	follow = []
	for f in follow_paths:
		follow.append(get_node(f))

func _physics_process(delta):
	if len(follow) > 1:
		var avg = Vector2(0,0)
		for f in follow:
			avg += f.global_position
		avg /= len(follow)
		
		var furthest = Vector2(0,0)
		var furthest_r = 0
		for f in follow:
			var v = f.global_position - avg
			var r = v.length()
			if r > furthest_r:
				furthest = v
				furthest_r = r
		
		# this is purely heuristic
		furthest.y *= 1.5
		furthest_r = furthest.length()
		var z = max(1, furthest_r / get_viewport().size.x * 3)
		zoom.x = z
		zoom.y = z
		set_global_position(avg)
	elif len(follow) == 1:
		set_global_position(follow[0].global_position)

func remove_follow(node):
	follow.erase(node)
	
func add_follow(node):
	if follow.find(node) == -1:
		follow.append(node)

