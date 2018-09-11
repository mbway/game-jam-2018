extends "res://Player/Player.gd"
# the approach of splitting the pathfinding into local/global seems to have been tried before in http://ctrl500.com/tech/teaching-the-ai-to-find-a-path-in-awesomenauts/



#TODO: it may be a problem that the collision detectors can collide with bullet shells
#TODO: movement fidelity would probably be improved if the target could be moved or advanced before the player reaches it if appropriate, for example if the player is in the air and directly over the target, the target could begin to move over the platform in the direction the player would go anyway once it touches the floor

var state = 'explore'

# path following

# an array of dictionaries with 'pos' and 'id' elements. 'id' indexes into nav.nodes and a 'pos' is a Vector2.
# if the node was added temporarily (ie first or last in path) then id may be null
var path = [] # a list of targets to follow to reach the waypoint
onready var _target = null # the next target that the player should move directly towards
const CHECK_PROGRESS_EVERY = 0.4 # seconds
const width = 32.0
const height = 64.0
var last_progress = INF # last distance to the target
var time_since_last_progress = 0 # time since the progress was measured

func _ready():
	_get_platforms()
	_get_node_platforms()

func get_target_relative():
	return Vector2(0, 0) if _target == null else _target.pos - position

# 'close' is defined based on how close the player should be to the target before moving on to the next.
# fine control is required in x because moving on early could mean the player is not yet standing on a platform.
func target_close(t):
	return abs(t.x) < width / 2 and (-height < t.y and t.y < 1.5*height)


func _set_target(t):
	_target = t
	last_progress = INF
	time_since_last_progress = 0
	$AINodes.falls_short = false
	$AINodes.fall_short_pos = null

func _next_target():
	_set_target(null if path.empty() else path.pop_front())
	return get_target_relative()

func _physics_process(delta):
	if is_dead():
		return

	var on_floor = is_on_floor()
	time_since_last_progress += delta

	var t = get_target_relative() # vector from the current position to the target

	# check whether to move onto the next target
	if target_close(t):
		t = _next_target()
	elif abs(t.x) < width and t.y > height and not path.empty():
		var platform_a = get_target_platform(_target)
		var platform_b = get_target_platform(path[0])
		print(platform_a, ' ', platform_b)
		if platform_a != -1 and platform_a == platform_b:
			t = _next_target()

	#TODO: not sure this is working
	# check that sufficient progress has been made since the last time it was checked
	if _target != null and time_since_last_progress > CHECK_PROGRESS_EVERY:
		var this_progress = t.x*t.x*4 + t.y*t.y
		if this_progress > last_progress:
			set_waypoint(_target.pos if path.empty() else path[-1].pos)
		else:
			last_progress = this_progress


	# horizontal movement
	if abs(t.x) < 5:
		move_direction = 0 # dead zone once close enough
	elif abs(t.x) < 10:
		move_direction = t.x/10 # analog control for fine movements
	else:
		move_direction = sign(t.x)

	#TODO: if currently in the air and the target changes to be above, may want to touch the floor before jumping if there is ground below

	# jumping
	var reason = null # the human readable explanation of the AI action for debugging purposes
	var state = jump_physics.state
	var State = jump_physics.State

	if state == State.JUMP_FINISHED:
		reason = 'jump finished'
		jump_pressed = false # no point holding jump any longer

	elif [State.FLOOR, State.EDGE_PLATFORM, State.PREEMPTIVE_JUMP].has(state): # able to start jumping from these states
		# reasons why the AI may want to initiate a jump when on the floor
		if $AINodes.is_obstructed(move_direction):
			# need to jump over an obstacle
			reason = 'obstructed'
			jump_pressed = true
		elif $AINodes.is_about_to_fall(move_direction) and falls_short(t):
			# at the edge of a platform and don't want to just fall off because that wouldn't reach the target
			reason = 'about to fall'
			jump_pressed = true
		elif abs(t.x) < width/2 and t.y < -height:
			# target is directly above
			reason = 'target directly above'
			jump_pressed = true

	elif state == State.JUMPING:
		if velocity.y > -jump_physics.RELEASE_SPEED: # (negative is upwards)
			# the jump is past the apex so that releasing won't clamp the velocity
			# the player may still travel upwards a little before falling
			reason = 'reached apex'
			jump_pressed = false

		elif not $AINodes.is_obstructed(move_direction):
			if t.y > height:
				# target below and don't have to continue jumping because there isn't an obstruction
				# may want to stop the jump early if already over the floor where the target is
				var ray = cast_ray_down(t.y + height)
				if ray != null:
					reason = 'over floor'
					jump_pressed = false

			elif not falls_short(t):
				# can reach the target by falling from this location
				jump_pressed = false

	elif state == State.FALLING:
		if t.y < -height:
			# the player is falling but the target is still above, try to double jump
			reason = 'target still above'
			jump_pressed = true

		else:
			var ray = cast_ray_down(t.y + height)
			# only matters if the player falls short if it doesn't first hit the floor
			# this isn't the best way of checking this (should check for collisions along
			# the predicted trajectory) but works as a first approximation.
			if ray == null and abs(t.x) > width and falls_short(t):
				reason = 'falls short'
				jump_pressed = true

	if reason != null:
		print('%s: jump_pressed = %s' % [reason, jump_pressed])

#TODO: falls short needs to allow for when the predicted point is above the same platform as that of the node

func falls_short(rel_target):
	# use motion equations to estimate the falling trajectory of the player.
	# assume the horizontal velocity remains constant.
	# solve for the time at which the player falls to player.y == target.y acting under gravity alone.
	# then plug that time in to get player.x. If the player cannot reach target.x
	# before falling past it then a double jump is required.

	# note: clamping to MAX_SPEED is not taken into account, the real player may descend slower than predicted.
	# This isn't a problem, it just means that the function is over cautious and may jump when not necessary

	if rel_target.y < 0:
		return true # target is above, so must fall short

	# since target is relative, starting at (0,0)
	# s = u*t + 1/2*a*t^2
	# solve for t
	var u = clamp(velocity.y, -jump_physics.RELEASE_SPEED, INF)
	var descrim = u*u - 4 * 0.5 * jump_physics.GRAVITY * -rel_target.y   # b^2-4ac
	if descrim < 0:
		# no solutions, so falls short
		return true

	# the positive solution for time
	var t = (-u + sqrt(descrim))/jump_physics.GRAVITY

	# plug in to find player.x
	# assume that x velocity is constant
	# s = vt
	var x = velocity.x * t # final x position
	# flip the sign if travelling left so that short_by = 0 when exactly the
	# same and > 0 when falling short and < 0 when overshooting.
	var short_by = (rel_target.x - x) * sign(velocity.x)
	var falls_short = bool(short_by > width/2)

	var pos = Vector2(x, rel_target.y)
	$AINodes.falls_short = falls_short
	$AINodes.fall_short_pos = to_global(pos)

	return falls_short




# _unhandled_input allows the GUI to process events first
func _unhandled_input(event):
	if event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_LEFT:
				var mouse = get_global_mouse_position()
				print('tp %s %s,%s; player_set %s waypoint %s,%s;;' % [config.num, global_position.x, global_position.y, config.num, mouse.x, mouse.y])
				set_waypoint(mouse)

# cast a ray of the given length and position (default: current position)
# returns null if no intersection, and [position, object] if there was.
# the test is performed on layer 1 with this player as an exception, so the ray may hit another player or the map
func cast_ray_down(length, pos=null):
	if pos == null:
		pos = global_position + Vector2(0, 32) # the player is 64px tall, positioned at 0,0
	if length <= 0:
		return null
	var space_state = get_world_2d().direct_space_state
	# cast in layer 1 (Player-Map layer) with this player as an exception. Only collides with other players and the map
	var result = space_state.intersect_ray(pos, pos + Vector2(0, length), [self], 1)
	if result.empty():
		return null
	else:
		return [result.position, result.collider]

func set_waypoint(waypoint):
	if nav == null:#TODO: remove check once made compulsory
		return
	#TODO: when in the air, either don't set a waypoint until landed, or project the position down to the floor
	if not is_on_floor():
		var collision = cast_ray_down(1000)
		if collision == null:
			path = nav.get_path(position, waypoint) # nothing else that can be done
		else:
			path = nav.get_path(collision[0], waypoint)
	else:
		path = nav.get_path(position, waypoint)
	_set_target(null)
	var c = $AINodes/Path.curve
	c.clear_points()
	for i in path:
		c.add_point(i.pos)

func get_target_platform(t):
	return _closest_platform_under(t.pos, 64) if t.id == null else node_platforms[t.id]

var platforms = null
func _get_platforms():
	platforms = []
	for c in G.get_scene().get_node('Map/Collision').get_children(): # list of StaticBody2D
		var pos = c.position
		var half_extents = c.get_node('CollisionShape2D').shape.extents
		platforms.append([pos.x, pos.x+2*half_extents.x, pos.y]) # x_left, x_right, y

	#var dd = G.get_scene().debug_draw
	#for p in platforms: dd.add_line_segment(Vector2(p[0], p[2]), Vector2(p[1], p[2]))

# the index of the platform (collidable rectangle in the node Map/Collision) for each node in the graph.
var node_platforms = null
func _get_node_platforms():
	var max_distance = 64
	node_platforms = []
	for n in nav.nodes:
		node_platforms.append(_closest_platform_under(n, max_distance))

	for i in range(nav.nodes.size()):
		if node_platforms[i] != -1:
			var n = nav.nodes[i]
			var p = platforms[node_platforms[i]]

func _closest_platform_under(point, max_distance):
	var platform = -1
	var distance = INF
	for pi in range(platforms.size()):
		var p = platforms[pi]
		if p[0] <= point.x and point.x <= p[1]: # above or below the platform
			var height = p[2] - point.y
			if height >= 0 and height <= distance:
				platform = pi
				distance = height
	return platform if distance <= max_distance else -1



