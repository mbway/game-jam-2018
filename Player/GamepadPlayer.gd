extends "res://Player/Player.gd"

var aim_direction = Vector2(0, 0)


# _unhandled_input allows the GUI to process events first
func _unhandled_input(event):
	if event.device != config.gamepad_id:
			return

	if event is InputEventJoypadButton:
		var b = event.button_index
		if event.pressed:
			if b == JOY_XBOX_A or event.button_index == JOY_L:
				jump_pressed = true
			elif b == JOY_XBOX_X:
				select_next_weapon(1)
			elif b == JOY_XBOX_Y:
				select_next_weapon(-1)
			elif b == JOY_R:
				fire_pressed = true

		else: # released
			if b == JOY_XBOX_A or b == JOY_L:
				jump_pressed = false
			elif b == JOY_R:
				fire_pressed = false
				fire_held = false
	elif event is InputEventJoypadMotion:
		if event.axis == G.Joy.LOOK_X:
			aim_direction.x = event.axis_value
			update_weapon_angle()
		elif event.axis == G.Joy.LOOK_Y:
			aim_direction.y = event.axis_value
			update_weapon_angle()
		elif event.axis == G.Joy.MOVE_X:
			move_direction = event.axis_value
			if abs(move_direction) < G.JOY_DEADZONE:
				move_direction = 0


func update_weapon_angle():
	if aim_direction.length() > G.JOY_DEADZONE: # only update when outside deadzone
		weapon_angle = aim_direction.angle()
