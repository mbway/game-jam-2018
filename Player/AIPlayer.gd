extends "res://Player/Player.gd"

#TODO: it may be a problem that the collision detectors can collide with bullet shells

func _physics_process(delta):
	var on_floor = is_on_floor()
	var now = OS.get_ticks_msec()
	
	# moving
	var tx = $AINodes/MoveTarget.position.x
	if abs(tx) < 5:
		move_direction = 0
	elif abs(tx) < 10:
		move_direction = tx/10 # analog control for fine movements
	else:
		move_direction = sign(tx)
	
	# jumping
	var t = $AINodes/MoveTarget.position
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

