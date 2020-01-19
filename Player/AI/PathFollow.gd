extends Node
# the approach of splitting the pathfinding into local/global seems to have been tried before in http://ctrl500.com/tech/teaching-the-ai-to-find-a-path-in-awesomenauts/

#TODO: could probably optimise the pathfinding by having a variable like check_after which is set based on the current player state to decide when the jump state should be re-evaluated. At the moment checks are carried out every tick which may be too much if many AI players are in the scene

# tips for debugging pathfinding: pause the game after the target or jump_pressed state changes, then examine the reasons for the decision, then unpause the game with the terminal

var G = globals

# an array of dictionaries with 'pos' and 'id' elements. 'id' indexes into nav.nodes and a 'pos' is a Vector2.
# if the node was added temporarily (ie first or last in path) then id may be null
var path := [] # a list of targets to follow to reach the waypoint
onready var _target = null # the next target that the player should move directly towards

const CHECK_PROGRESS_EVERY := 2.0 # seconds
const BUFFER_X := 32.0
const BUFFER_Y := 64.0
var last_progress := INF # last distance to the target
var time_since_last_progress := 0.0 # time since the progress was measured
# the time between detecting that the player could reach the target by releasing
# jump, to actually releasing jump. A small buffer is required to account for
# the inaccuracy in the can_reach_target prediction. If jump is released
# immediately then a subsequent test may indicate that the player can't reach
# the target any more, causing an unnecessary double jump.
var jump_release_delay := 0.02
var jump_release_timer = null

var verbose := 0

# node platforms
var platforms = null # the tops of collision rects of the map. List of [left_x, right_x, y, one_way]
# list of indices into platforms (or null) corresponding to the nodes of nav.
# ie node_platforms[n] = index of the platform node n is above, or null if it is not above any.
var node_platforms = null
const platform_search_distance := 64

var player = null
var AINodes = null
var nav = null

func _init(set_player: Player):
	self.player = set_player
	nav = player.nav
	assert(nav.position == Vector2(0, 0))
	AINodes = player.get_node('AINodes')
	platforms = _get_platforms()
	node_platforms = _get_node_platforms()


func get_target_relative():
	return Vector2(0, 0) if _target == null else _target.pos - player.position

# 'close' is defined based on how close the player should be to the target before moving on to the next.
# fine control is required in x because moving on early could mean the player is not yet standing on a platform.
func target_close(t: Vector2) -> bool:
	return abs(t.x) < BUFFER_X / 2 and (-BUFFER_Y/2 < t.y and t.y < 1.5*BUFFER_Y)


func _set_target(set_target) -> void:
	player._on_passed_through(_target)
	_target = set_target
	last_progress = INF
	time_since_last_progress = 0
	AINodes.falls_short = false
	AINodes.fall_short_pos = null

func _next_target():
	_set_target(null if path.empty() else path.pop_front())
	jump_release_timer = null # new target so have to re-evaluate whether jump should be released
	return get_target_relative()

func process(delta: float) -> void:
	if player.is_dead():
		return

	time_since_last_progress += delta
	var t = get_target_relative() # vector from the current position to the target
	var state = player.jump_physics.state
	var State = player.jump_physics.State
	var target_above = bool(t.y < -BUFFER_Y/2)
	var target_below = bool(t.y > BUFFER_Y)

	# check whether to move onto the next target
	var reason = null # the human readable explanation of the AI action for debugging purposes
	if _target == null and path.empty():
		# no path to follow
		pass
	else:
		if target_close(t):
			if state == State.FLOOR:
				# since a full jump can be initiated from this state, safe to move on
				reason = 'close and on floor'
				t = _next_target()
			elif path.empty():
				# since there is nothing else to aim for, stop
				reason = 'close and path finished'
				t = _next_target()
			elif not path.empty():
				# can't initiate a full jump so have to be careful about whether to move on yet
				# only move on if the next target is on the same platform as the
				# current target, or the current target is in mid air.
				var platform_a = get_target_platform(_target)
				var platform_b = get_target_platform(path[0])
				if platform_a == -1 or platform_a == platform_b:
					reason = 'close and player mid-air, but next shares the same platform'
					t = _next_target()
		elif abs(t.x) < BUFFER_X and target_below and not path.empty():
			# not close to the current target, however the player is above the
			# current target and this isn't the end of the path. Can move on if the
			# next target is above the same platform. The assumption is that the
			# player will land somewhere on the platform regardless, so they don't
			# have to fall straight down onto the target before moving on.
			# (only applies if the current target is over a platform and not in mid air)
			var platform_a = get_target_platform(_target)
			var platform_b = get_target_platform(path[0])
			if platform_a != -1 and platform_a == platform_b:
				reason = 'target below and next shares the same platform'
				t = _next_target()

	if verbose > 0 and reason != null:
		print('next target %s, reason: "%s"' % [null if _target == null else _target.pos, reason])
		#get_tree().paused = true

	# check that sufficient progress has been made since the last time it was checked
	if _target != null and time_since_last_progress > CHECK_PROGRESS_EVERY:
		# smaller is closer to the target
		var this_progress = t.x*t.x*4 + t.y*t.y # weight x progress higher
		# must improve upon the previous progress by at least 10%
		if this_progress < last_progress*0.9:
			last_progress = this_progress
		else:
			if verbose > 0:
				print('insufficient progress: re-planning route')
			set_waypoint(_target.pos if path.empty() else path[-1].pos)


	# horizontal movement
	if abs(t.x) < 5:
		player.move_direction = 0 # dead zone once close enough
	elif abs(t.x) < 10:
		player.move_direction = t.x/10 # analog control for fine movements
	else:
		player.move_direction = sign(t.x)

	if _target == null:
		# horizontal movement control (above) still important to come to rest, but jumping is not necessary
		player.jump_pressed = false
		return


	# jumping
	reason = null # the human readable explanation of the AI action for debugging purposes

	if state == State.JUMP_FINISHED:
		reason = 'jump finished'
		player.jump_pressed = false # no point holding jump any longer

	elif state == State.FLOOR:
		# reasons why the AI may want to initiate a jump when on the floor
		if not player.jump_pressed:
			if AINodes.is_obstructed(player.move_direction):
				# need to jump over an obstacle
				reason = 'obstructed'
				player.jump_pressed = true
			elif AINodes.is_about_to_fall(player.move_direction) and not can_fall_to_target():
				# at the edge of a platform and don't want to just fall off because that wouldn't reach the target
				reason = 'about to fall'
				player.jump_pressed = true
			elif abs(t.x) < 2*BUFFER_X: # either above or below
				if target_above:
					# target is (almost directly) above
					reason = 'target above'
					player.jump_pressed = true
				elif target_below:
					var platform = _closest_platform_under(player.global_position)
					if platform != -1 and platforms[platform][3]: # one-way
						# target is (almost directly) below a one way platform
						reason = 'target below one-way platform'
						player.try_fall_through()

	elif state == State.EDGE_PLATFORM or state == State.PREEMPTIVE_JUMP:
		# don't do anything in these states.
		# sometimes causes problems such as is_obstructed during EDGE_PLATFORM
		# causing unnecessary jumps. Preemptive jumps cause the player to
		# appear to bounce along the ground as a small jump is initiated
		# immediately upon landing.
		pass

	elif state == State.JUMPING:
		if player.velocity.y > -player.jump_physics.RELEASE_SPEED: # (negative is upwards)
			# the jump is past the apex so that releasing won't clamp the velocity
			# the player may still travel upwards a little before falling
			reason = 'reached apex'
			player.jump_pressed = false

		elif jump_release_timer != null:
			# can fall to target already triggered, but jump is held for a
			# little while before releasing.
			jump_release_timer -= delta
			if jump_release_timer < 0:
				reason = 'jump release timeout'
				player.jump_pressed = false
				jump_release_timer = null

		elif not AINodes.is_obstructed(player.move_direction) and can_fall_to_target(0):
			# can't release jump if the player is currently trying to get over
			# an obstacle. When checking whether the player can fall to the
			# target, the player must be able to 'comfortably' reach the target
			# before releasing jump, whereas when performing the same test to
			# determine whether to double jump, a small buffer is used so that
			# the player double jumps if it can only just reach the target.
			reason = 'can fall to target'
			# don't release immediately to allow for some inaccuracies in the can_fall_to_target prediction
			jump_release_timer = jump_release_delay

	elif state == State.FALLING:
		if player.jump_physics.mid_air_jumps == 0:
			# don't want to initiate a preemptive jump because that causes
			# unnecessary bouncing when a target changes while the player is
			# close, but in mid air, then the falls_short test returns true.
			pass
		else:
			# if the player can reach the target before falling to its y
			# position, or can land on the same platform as the target by that
			# time, then there is no need to double jump. One thing this doesn't
			# take into account is collisions along the way, but the navigation
			# graph should be designed to avoid this (eg put a node in mid air
			# to force the player through that node before continuing)
			if not can_fall_to_target():
				reason = 'falls short'
				player.jump_pressed = true

	if verbose > 0 and reason != null:
		var mid_air := bool(player.jump_pressed and state == State.FALLING)
		print('%s: player.jump_pressed = %s%s' % [reason, player.jump_pressed, ' (mid air)' if mid_air else ''])
		#get_tree().paused = true


# if the player released jump right now (or kept it released), would it be able
# to reach to within 'buffer' pixels of the target, or at least land on the
# platform that the target resides on.
func can_fall_to_target(buffer: float = BUFFER_X/2) -> bool:
	# use motion equations to estimate the falling trajectory of the player.
	# solve for the time at which the player falls to player.y == target.y
	# acting under gravity alone. Then plug that time in to get the x
	# displacement. If the player cannot reach target.x before falling past it
	# then a double jump is required.

	# note: clamping of falling speed to MAX_SPEED is not taken into account,
	# the real player may descend slower than predicted.

	var rel_target = get_target_relative()

	if rel_target.y <= 0:
		# target is above, so must fall short unless the player is over the same platform as the target
		# (the target may only be slightly above the player)
		var fall_platform = _closest_platform_under(player.global_position)
		var can_reach := bool(fall_platform != -1 and fall_platform == get_target_platform(_target))
		if verbose > 0:
			print('can reach (target above but can reach platform) = %s' % can_reach)
		return can_reach

	# since target is relative, starting at (0,0)
	# s = u*t + 1/2*a*t^2
	# solve for t
	var u = clamp(player.velocity.y, -player.jump_physics.RELEASE_SPEED, INF)
	var descrim = u*u - 4 * 0.5 * player.jump_physics.GRAVITY * -rel_target.y   # b^2-4ac
	if descrim < 0:
		# no solutions, so falls short
		if verbose > 0:
			print('can reach (no solutions) = %s' % false)
		return false

	# the positive solution for time
	var t = (-u + sqrt(descrim))/player.jump_physics.GRAVITY

	# plug in t to find player.x
	# the player accelerates until it reaches the maximum velocity
	# v = u + at
	# (v-u)/a = t
	var x = 0
	if player.move_direction != 0:
		var v = sign(player.move_direction) * player.MAX_SPEED
		var acc_time = 0

		if abs(player.velocity.x) < player.MAX_SPEED:
			# some time is spent accelerating
			var a = sign(player.move_direction) * player.ACCELERATION
			# time to reach max speed. If there isn't enough time to reach max speed: clamp.
			acc_time = min(t, (v-player.velocity.x)/a)
			# distance covered while accelerating
			# s = ut + 1/2at^2
			x = player.velocity.x*acc_time + 0.5 * a * acc_time*acc_time

		if acc_time < t:
			# there is some time spent travelling at max speed
			# s = vt
			x += v * (t-acc_time)

	# flip the sign if travelling left so that short_by = 0 when exactly the
	# same and > 0 when falling short and < 0 when overshooting.
	var short_by = (rel_target.x - x) * sign(player.move_direction)
	var can_reach = bool(short_by < buffer)
	var pos = player.to_global(Vector2(x, rel_target.y))

	AINodes.falls_short = not can_reach
	AINodes.fall_short_pos = pos

	if can_reach:
		if verbose > 0:
			print('can reach = %s' % can_reach)
		return true
	else:
		# the platform under the fall location, if it is the same as the target
		# then the player can still reach it by falling (then walking after landing).
		var fall_platform = _closest_platform_under(pos)
		can_reach = fall_platform != -1 and fall_platform == get_target_platform(_target)
		if verbose > 0:
			print('can reach (falls short but can reach platform?) = %s (%s =?= %s)' % [can_reach, fall_platform, get_target_platform(_target)])
		return can_reach


#TODO: prevent the jolt which occurs when the waypoint changes

func clear_path():
	_target = null # didn't actually reach the target, so don't want it passed to _on_passed_through
	_set_target(null) # clean up timers etc
	path.clear()

func path_append(node_id):
	if node_id != null:
		path.append({'pos': nav.get_node_pos(node_id), 'id': node_id})

func _set_from_path_along_graph(path_along_graph):
	path = []
	for i in range(path_along_graph.points.size()):
		var pos = path_along_graph.points[i]
		if not can_skip_waypoint(pos):
			path.append({'pos': pos, 'id': path_along_graph.ids[i]})

func can_skip_waypoint(pos: Vector2) -> bool:
	return player.is_on_floor() and target_close(pos - player.position)

# get the ids of the nodes to the left and right of the given position on the
# same platform as pos. Returns null if pos is not on a platform. The left or
# right ids may be null (but not both) if there are no nodes in that direction.
func get_nearest_platform_nodes(pos):
	var platform = _closest_platform_under(pos)
	if platform == -1:
		return null

	# positive is to the right
	var left = null
	var left_dist = -INF
	var right = null
	var right_dist = INF
	for n in range(node_platforms.size()):
		if node_platforms[n] == platform:
			# n is on the same platform as pos
			var dist = nav.get_node_pos(n).x - pos.x

			if 0 <= dist and dist < right_dist:
				right = n
				right_dist = dist

			elif left_dist < dist and dist <= 0:
				left = n
				left_dist = dist

	if left == null and right == null:
		return null
	else:
		return [left, right]


# returns whether the waypoint was set (won't be set if the player is in mid air and not above a platform)
func set_waypoint(waypoint: Vector2) -> bool:
	if nav == null:#TODO: remove check once made compulsory
		return false
	if not player.is_on_floor():
		var collision = player.cast_ray_down(1000)
		if collision == null:
			return false # didn't set because it wouldn't be safe (the player might fall and die)
		else:
			_set_from_path_along_graph(nav.get_shortest_path(collision.pos, waypoint))
	else:
		_set_from_path_along_graph(nav.get_shortest_path(player.position, waypoint))
	_set_target(null)
	_update_ai_nodes()
	return true

func _update_ai_nodes() -> void:
	var c: Curve2D = AINodes.get_node('Path').curve
	c.clear_points()
	for i in path:
		c.add_point(i.pos)

# returns the index of the closest platform under the given point
# returns -1 if no platform is found within max_distance
func _closest_platform_under(point, max_distance=platform_search_distance):
	var platform_index = -1
	var distance = max_distance
	for pi in range(platforms.size()):
		var p = platforms[pi]
		if p[0] <= point.x and point.x <= p[1]: # above or below the platform
			var height = p[2] - point.y
			if height >= 0 and height <= distance:
				platform_index = pi
				distance = height
	return platform_index

func get_target_platform(t):
	if t == null:
		return -1
	return _closest_platform_under(t.pos) if t.id == null else node_platforms[t.id]

func _get_platforms() -> Array:
	var found_platforms = []
	var map = G.get_scene().get_node('Map')
	for c in map.get_node('Collision').get_children(): # list of StaticBody2D
		var pos = c.position
		var half_extents = c.get_node('CollisionShape2D').shape.extents
		found_platforms.append([pos.x, pos.x+2*half_extents.x, pos.y, false]) # left_x, right_x, y, one_way

	if map.has_node('OneWayCollision'): # not every map has need for one way collisions
		for c in map.get_node('OneWayCollision').get_children(): # list of StaticBody2D
			var pos = c.position
			var half_extents = c.get_node('CollisionShape2D').shape.extents
			found_platforms.append([pos.x, pos.x+2*half_extents.x, pos.y, true]) # left_x, right_x, y, one_way

	#var dd = G.get_scene().debug_draw
	#for p in found_platforms: dd.add_line_segment(Vector2(p[0], p[2]), Vector2(p[1], p[2]))

	return found_platforms

# the index of the platform (collidable rectangle in the node Map/Collision) for each node in the graph.
func _get_node_platforms():
	var node_platforms = []
	var node_positions = nav.get_node_positions()
	for n in node_positions:
		node_platforms.append(_closest_platform_under(n))

	for i in range(node_positions.size()):
		if node_platforms[i] != -1:
			var n = node_positions[i]
			var p = platforms[node_platforms[i]]
	return node_platforms


