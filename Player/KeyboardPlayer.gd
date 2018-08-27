extends "res://Player/Player.gd"

var left_pressed = false
var right_pressed = false

func _input(event):
	# mouse wheel events have to be handled specially :(
	# this is apparently because they are more short-lived
	# mouse scroll to switch weapons
	if event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_WHEEL_UP:
				select_next_weapon(-1)
			elif b == BUTTON_WHEEL_DOWN:
				select_next_weapon(1)
			elif b == BUTTON_LEFT:
				fire_pressed = true
		else: # released
			if b == BUTTON_LEFT:
				fire_pressed = false
				fire_held = false

	elif event is InputEventKey:
		var k = event.scancode
		if event.pressed and not event.is_echo(): # disregard key repeats
			if k == KEY_W or k == KEY_SPACE:
				try_jump()
			elif k == KEY_A:
				left_pressed = true
				update_move_direction()
			elif k == KEY_D:
				right_pressed = true
				update_move_direction()
		elif not event.pressed: # released
			if k == KEY_W or k == KEY_SPACE:
				jump_released = true
			elif k == KEY_A:
				left_pressed = false
				update_move_direction()
			elif k == KEY_D:
				right_pressed = false
				update_move_direction()

func _physics_process(delta):
	# mouse aim
	# updating every physics frame because it is likely that either the player or mouse has moved
	# maths copied from power defence
	var gun_pos = current_weapon.get_position()
	var mouse_pos = get_local_mouse_position()
	var angle = mouse_pos.angle_to_point(gun_pos)
	var d = (mouse_pos - gun_pos).length()
	if d != 0:
		var o = (current_weapon.get_node('Muzzle').get_position() - gun_pos).y
		var angle_correction = asin(o/d)
		 # as of Godot 3.0.6 there is a bug where is_nan(NAN) == false, so this fix doesn't help yet
		if not is_nan(angle_correction):
			if abs(weapon_angle+angle_correction) > PI/2:
				angle += angle_correction
			else:
				angle -= angle_correction
	weapon_angle = angle # atomic update
	


func update_move_direction():
	var direction = 0
	if left_pressed:
		direction += -1
	if right_pressed:
		direction += 1
	move_direction = direction # atomic update