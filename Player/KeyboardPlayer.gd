extends "res://Player/Player.gd"

var left_pressed = false
var right_pressed = false

# can't use _unhandled_input otherwise won't receive mouse events when over a Control node
func _input(event):
	if event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_WHEEL_UP:
				inventory.cycle_selection(-1)
			elif b == BUTTON_WHEEL_DOWN:
				inventory.cycle_selection(1)
			elif b == BUTTON_LEFT:
				fire_pressed = true
		else: # released
			if b == BUTTON_LEFT:
				fire_pressed = false
				fire_held = false


# _unhandled_input allows the GUI to process events first
func _unhandled_input(event):
	# mouse wheel events have to be handled specially :(
	# this is apparently because they are more short-lived
	# mouse scroll to switch weapons
	if event is InputEventKey:
		var k = event.scancode
		if event.pressed and not event.is_echo(): # disregard key repeats
			if k == KEY_W or k == KEY_SPACE:
				jump_pressed = true
			elif k == KEY_S:
				try_fall_through()
			elif k == KEY_A:
				left_pressed = true
				update_move_direction()
			elif k == KEY_D:
				right_pressed = true
				update_move_direction()
		elif not event.pressed: # released
			if k == KEY_W or k == KEY_SPACE:
				jump_pressed = false
			elif k == KEY_A:
				left_pressed = false
				update_move_direction()
			elif k == KEY_D:
				right_pressed = false
				update_move_direction()

func _process(delta):
	# mouse aim (updating every frame because it is likely that either the player or mouse has moved)
	set_weapon_angle(weapon_aim_angle(get_local_mouse_position()))



func update_move_direction():
	var direction = 0
	if left_pressed:
		direction += -1
	if right_pressed:
		direction += 1
	move_direction = direction # atomic update
