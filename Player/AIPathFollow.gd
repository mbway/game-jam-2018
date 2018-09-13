# the approach of splitting the pathfinding into local/global seems to have been tried before in http://ctrl500.com/tech/teaching-the-ai-to-find-a-path-in-awesomenauts/

#TODO: could probably optimise the pathfinding by having a variable like check_after which is set based on the current player state to decide when the jump state should be re-evaluated. At the moment checks are carried out every tick which may be too much if many AI players are in the scene

# tips for debugging pathfinding: pause the game after the target or jump_pressed state changes, then examine the reasons for the decision, then unpause the game with the terminal

var G = globals

# an array of dictionaries with 'pos' and 'id' elements. 'id' indexes into nav.nodes and a 'pos' is a Vector2.
# if the node was added temporarily (ie first or last in path) then id may be null
var path = [] # a list of targets to follow to reach the waypoint
onready var _target = null # the next target that the player should move directly towards
const CHECK_PROGRESS_EVERY = 2.0 # seconds
const width = 32.0
const height = 64.0
var last_progress = INF # last distance to the target
var time_since_last_progress = 0 # time since the progress was measured
# the time between detecting that the player could reach the target by releasing
# jump, to actually releasing jump. A small buffer is required to account for
# the inaccuracy in the can_reach_target prediction. If jump is released
# immediately then a subsequent test may indicate that the player can't reach
# the target any more, causing an unnecessary double jump.
var jump_release_delay = 0.02
var jump_release_timer = null

# node platforms
var platforms = null
var node_platforms = null
const platform_search_distance = 64

var player = null
var AINodes = null

func _init(player):
	self.player = player
	AINodes = player.get_node('AINodes')
	platforms = _get_platforms()
	node_platforms = _get_node_platforms()


func get_target_relative():
	return Vector2(0, 0) if _target == null else _target.pos - player.position

# 'close' is defined based on how close the player should be to the target before moving on to the next.
# fine control is required in x because moving on early could mean the player is not yet standing on a platform.
func target_close(t):
	return abs(t.x) < width / 2 and (-height < t.y and t.y < 1.5*height)


func _set_target(t):
	_target = t
	last_progress = INF
	time_since_last_progress = 0
	AINodes.falls_short = false
	AINodes.fall_short_pos = null

func _next_target():
	_set_target(null if path.empty() else path.pop_front())
	jump_release_timer = null # new target so have to re-evaluate whether jump should be released
	return get_target_relative()

func process(delta):
	if player.is_dead():
		return

	var on_floor = player.is_on_floor()
	time_since_last_progress += delta
	var t = get_target_relative() # vector from the current position to the target
	var state = player.jump_physics.state
	var State = player.jump_physics.State
	var target_above = bool(t.y < -height)
	var target_below = bool(t.y > height)

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
		elif abs(t.x) < width and target_below and not path.empty():
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

	#if reason != null:
		#print('next target %s, reason: "%s"' % [null if _target == null else _target.pos, reason])
		#get_tree().paused = true

	# check that sufficient progress has been made since the last time it was checked
	if _target != null and time_since_last_progress > CHECK_PROGRESS_EVERY:
		# smaller is closer to the target
		var this_progress = t.x*t.x*4 + t.y*t.y # weight x progress higher
		# must improve upon the previous progress by at least 10%
		if this_progress < last_progress*0.9:
			last_progress = this_progress
		else:
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
			elif abs(t.x) < 2*width and target_above:
				# target is (almost directly) above
				reason = 'target above'
				player.jump_pressed = true

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

	#if reason != null:
		#var mid_air = bool(player.jump_pressed and state == State.FALLING)
		#print('%s: player.jump_pressed = %s%s' % [reason, player.jump_pressed, ' (mid air)' if mid_air else ''])
		#get_tree().paused = true

# if the player released jump right now (or kept it released), would it be able
# to reach to within 'buffer' pixels of the target, or at least land on the
# platform that the target resides on.
func can_fall_to_target(buffer=width/2):
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
		var fall_platform = _closest_platform_under(player.global_position, platform_search_distance)
		var can_reach = fall_platform != -1 and fall_platform == get_target_platform(_target)
		#print('can reach (target above but can reach platform) = %s' % can_reach)
		return can_reach

	# since target is relative, starting at (0,0)
	# s = u*t + 1/2*a*t^2
	# solve for t
	var u = clamp(player.velocity.y, -player.jump_physics.RELEASE_SPEED, INF)
	var descrim = u*u - 4 * 0.5 * player.jump_physics.GRAVITY * -rel_target.y   # b^2-4ac
	if descrim < 0:
		# no solutions, so falls short
		#print('can reach (no solutions) = %s' % false)
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
		#print('can reach = %s' % can_reach)
		return true
	else:
		# the platform under the fall location, if it is the same as the target
		# then the player can still reach it by falling (then walking after landing).
		var fall_platform = _closest_platform_under(pos, platform_search_distance)
		can_reach = fall_platform != -1 and fall_platform == get_target_platform(_target)
		#print('can reach (falls short but can reach platform?) = %s (%s =?= %s)' % [can_reach, fall_platform, get_target_platform(_target)])
		return can_reach



# cast a ray of the given length and position (default: current position)
# returns null if no intersection, and [position, object] if there was.
# the test is performed on layer 1 with this player as an exception, so the ray may hit another player or the map
func cast_ray_down(length, pos=null):
	if pos == null:
		pos = player.global_position + Vector2(0, 32) # the player is 64px tall, positioned at 0,0
	if length <= 0:
		return null
	var space_state = get_world_2d().direct_space_state
	# cast in layer 1 (Player-Map layer) with this player as an exception. Only collides with other players and the map
	var result = space_state.intersect_ray(pos, pos + Vector2(0, length), [self], 1)
	if result.empty():
		return null
	else:
		return [result.position, result.collider]

# returns whether the waypoint was set (won't be set if the player is in mid air and not above a platform)
func set_waypoint(waypoint):
	if player.nav == null:#TODO: remove check once made compulsory
		return
	if not player.is_on_floor():
		var collision = cast_ray_down(1000)
		if collision == null:
			return false # didn't set because it wouldn't be safe (the player might fall and die)
		else:
			path = player.nav.get_path(collision[0], waypoint)
	else:
		path = player.nav.get_path(player.position, waypoint)
	_set_target(null)
	var c = AINodes.get_node('Path').curve
	c.clear_points()
	for i in path:
		c.add_point(i.pos)
	return true


func get_target_platform(t):
	if t == null:
		return -1
	return _closest_platform_under(t.pos, 64) if t.id == null else node_platforms[t.id]

func _get_platforms():
	var platforms = []
	for c in G.get_scene().get_node('Map/Collision').get_children(): # list of StaticBody2D
		var pos = c.position
		var half_extents = c.get_node('CollisionShape2D').shape.extents
		platforms.append([pos.x, pos.x+2*half_extents.x, pos.y]) # x_left, x_right, y

	#var dd = G.get_scene().debug_draw
	#for p in platforms: dd.add_line_segment(Vector2(p[0], p[2]), Vector2(p[1], p[2]))

	return platforms

# the index of the platform (collidable rectangle in the node Map/Collision) for each node in the graph.
func _get_node_platforms():
	var node_platforms = []
	for n in player.nav.nodes:
		node_platforms.append(_closest_platform_under(n, platform_search_distance))

	for i in range(player.nav.nodes.size()):
		if node_platforms[i] != -1:
			var n = player.nav.nodes[i]
			var p = platforms[node_platforms[i]]
	return node_platforms

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



