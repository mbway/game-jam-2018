extends Camera2D

const SHAKE_DECAY = 10 # shake decay per second
const MAX_SHAKE = 200

var follow = [] # nodes to follow
var shake_amount = 0

func _process(delta):
	if shake_amount > 0.1:
		offset.x = rand_range(-1, 1) * shake_amount
		offset.y = rand_range(-1, 1) * shake_amount
		shake_amount -= shake_amount * SHAKE_DECAY * delta
		shake_amount = clamp(shake_amount, 0, MAX_SHAKE)
	else:
		shake_amount = 0
		offset.x = 0
		offset.y = 0

func shake(amount):
	shake_amount = min(shake_amount + amount, MAX_SHAKE)

func _physics_process(delta):
	var following = len(follow)
	
	if following == 1:
		set_global_position(follow[0].global_position)
		
	elif following > 1:
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
		furthest.y *= 1.7
		furthest_r = furthest.length()
		var z = max(1, furthest_r / get_viewport().size.x * 3)
		zoom.x = z
		zoom.y = z
		set_global_position(avg)
	

func remove_follow(node):
	follow.erase(node)
	update_settings()

func add_follow(node):
	if follow.find(node) == -1:
		follow.append(node)
	update_settings()

func update_settings():
	if len(follow) == 1:
		# prevents jittering
		smoothing_enabled = false
	else:
		smoothing_enabled = true
	
	
	

