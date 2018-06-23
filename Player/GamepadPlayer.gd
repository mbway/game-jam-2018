extends "res://Player/Player.gd"

var aim_direction = Vector2(0, 0)


func _input(event):
	if event.device != config.gamepad_id:
			return
	
	if event is InputEventJoypadButton:
		var b = event.button_index
		if event.pressed:
			if b == JOY_XBOX_A or event.button_index == JOY_L:
				try_jump()
			elif b == JOY_XBOX_X:
				select_next_weapon(1)
			elif b == JOY_XBOX_Y:
				select_next_weapon(-1)
			elif b == JOY_R:
				fire_pressed = true

		else: # released
			if b == JOY_XBOX_A or b == JOY_L:
				jump_released = true
			elif b == JOY_R:
				fire_pressed = false
				fire_held = false
	elif event is InputEventJoypadMotion:
		if event.axis == globals.JOY_LOOK_X:
			aim_direction.x = event.axis_value
			update_weapon_angle()
		elif event.axis == globals.JOY_LOOK_Y:
			aim_direction.y = event.axis_value
			update_weapon_angle()
		elif event.axis == globals.JOY_MOVE_X:
			move_direction = event.axis_value
			if abs(move_direction) < globals.JOY_DEADZONE:
				move_direction = 0
	

func update_weapon_angle():
	if aim_direction.length() > globals.JOY_DEADZONE: # only update when outside deadzone
		weapon_angle = aim_direction.angle()
