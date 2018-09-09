extends "res://Player/Player.gd"
# the approach of splitting the pathfinding into local/global seems to have been tried before in http://ctrl500.com/tech/teaching-the-ai-to-find-a-path-in-awesomenauts/



#TODO: it may be a problem that the collision detectors can collide with bullet shells
#TODO: movement fidelity would probably be improved if the target could be moved or advanced before the player reaches it if appropriate, for example if the player is in the air and directly over the target, the target could begin to move over the platform in the direction the player would go anyway once it touches the floor

var state = 'explore'

# path following
var path = [] # an array of targets to follow to reach the waypoint
onready var _target = null # a global vector specifying where the player should move to
const CHECK_PROGRESS_EVERY = 0.4 # seconds
const width = 32.0
const height = 64.0
var last_progress = INF # last distance to the target
var time_since_last_progress = 0 # time since the progress was measured


func get_target_relative():
	return Vector2(0, 0) if _target == null else _target - position

# 'close' is defined based on how close the player should be to the target before moving on to the next.
# fine control is required in x because moving on early could mean the player is not yet standing on a platform.
func target_close(t):
	return abs(t.x) < width / 2 and (-height < t.y and t.y < 1.5*height)

func _physics_process(delta):
	if is_dead():
		return

	var on_floor = is_on_floor()
	time_since_last_progress += delta

	var t =  get_target_relative() # vector from the current position to the target

	# check whether to move onto the next target
	if target_close(t):
		_target = null if path.empty() else path.pop_front()
		last_progress = INF
		time_since_last_progress = 0
		t = get_target_relative()
		$AINodes.falls_short = false
		$AINodes.fall_short_pos = null

	# check that sufficient progress has been made since the last time it was checked
	if _target != null and time_since_last_progress > CHECK_PROGRESS_EVERY:
		var this_progress = t.x*t.x*4 + t.y*t.y
		if this_progress > last_progress:
			set_waypoint(_target if path.empty() else path[-1])
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
	var reason = null
	if on_floor:
		if $AINodes.is_obstructed(move_direction):
			reason = 'obstructed'
			jump_pressed = true
		elif $AINodes.is_about_to_fall(move_direction):
			reason = 'about to fall'
			jump_pressed = true
		elif abs(t.x) < width/2 and t.y < -height:
			# target is directly above
			reason = 'target above'
			jump_pressed = true

	else:
		if jump_pressed:
			if velocity.y > -jump_physics.RELEASE_SPEED: # (negative is upwards)
				# the jump is past the apex so that releasing won't clamp the velocity
				reason = 'reached apex'
				jump_pressed = false

			elif t.y > height and not $AINodes.is_obstructed(move_direction):
				# target below and don't have to continue jumping because there isn't an obstruction
				# may want to stop the jump early if already over the floor where the target is
				var ray = cast_ray_down(2*height)
				if ray != null:
					reason = 'over floor'
					jump_pressed = false

			#elif not falls_short(t):
			#	jump_pressed = false

		elif jump_physics.state == jump_physics.State.FALLING:
			if t.y < -height:
				# the player is falling but the target is still above, try to double jump
				reason = 'target still above'
				jump_pressed = true
			else:
				var ray = cast_ray_down(2*height)
				# only matters if the player falls short if it doesn't first hit the floor
				# this isn't the best way of checking this (should check for collisions along
				# the predicted trajectory) but works as a first approximation.
				if ray == null and abs(t.x) > width and falls_short(t):
					reason = 'falls short'
					jump_pressed = true

	if reason != null:
		print('%s: jump_pressed = %s' % [reason, jump_pressed])

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
	var diff = (rel_target.x - x) * sign(velocity.x) # flip the sign if travelling left so that diff = 0 when exactly the same and > 0 when falling short and < 0 when overshooting
	var falls_short = bool(diff > width)

	var pos = Vector2(x, rel_target.y)
	$AINodes.falls_short = falls_short
	$AINodes.fall_short_pos = to_global(pos)

	return falls_short




func _input(event):
	if event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_LEFT:
				set_waypoint(get_global_mouse_position())

# cast a ray of the given length and position (default: current position)
# returns null if no intersection, and [position, object] if there was.
func cast_ray_down(length, pos=null):
	if pos == null:
		pos = global_position + Vector2(0, 32) # the player is 64px tall, positioned at 0,0
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
	_target = null
	var c = $AINodes/Path.curve
	c.clear_points()
	for vec in path:
		c.add_point(vec)




