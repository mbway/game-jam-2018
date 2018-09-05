extends "res://Player/Player.gd"

#TODO: it may be a problem that the collision detectors can collide with bullet shells

var state = 'explore'
var path = []
onready var _target = null # a global vector specifying where the player should move to
onready var astar = nav.get_astar()


func get_target_relative():
	return Vector2(0, 0) if _target == null else _target - position

func _physics_process(delta):
	var on_floor = is_on_floor()
	var now = OS.get_ticks_msec()

	var t =  get_target_relative()
	if t.length() < 40:
		_target = null if path.empty() else path.pop_front()
		t = get_target_relative()

	# moving
	if abs(t.x) < 5:
		move_direction = 0
	elif abs(t.x) < 10:
		move_direction = t.x/10 # analog control for fine movements
	else:
		move_direction = sign(t.x)

	# jumping
	var time_since_jump = now - last_jump_ms
	var want_to_jump = false

	if t.y < -20 and abs(t.x) < 400:
		# target above and relatively close
		want_to_jump = true
	else:
		# target not above
		var blocked_left = move_direction < 0 and $AINodes.is_blocked_left()
		var blocked_right = move_direction > 0 and $AINodes.is_blocked_right()

		if t.x < -10 and blocked_left:
			want_to_jump = true
		elif t.x > 10 and blocked_right:
			want_to_jump = true
		elif not on_floor and t.y > 10 and not (blocked_left or blocked_right):
			# mid-jump and target below
			jump_released = true

	if want_to_jump and (on_floor or time_since_jump > 250):
		try_jump()

func _input(event):
	if event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_LEFT:
				set_waypoint($AINodes/Waypoint.global_position)

func set_waypoint(location):
	return
	#TODO: add the current position to the astar then calculate the path then remove
	var id = astar.get_available_point_id()
	astar.add_point(id, position, 1.0)
	
	
	path = Array(nav.get_simple_path(position, location))
	_target = null
	var c = $AINodes/Path.curve
	c.clear_points()
	for vec in path:
		c.add_point(vec)




