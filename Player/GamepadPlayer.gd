extends "res://Player/Player.gd"

var aim_direction = Vector2(0, 0)

#TODO: ask Adam to playtest and decide what gamepad controls feel best
var jump_buttons = [JOY_XBOX_A, JOY_L, JOY_R2]
var auto_fire = true # aim just by looking
var auto_fire_cooldown = 0.2 # auto fire cooldown time
const FULL_ON_THRESHOLD = 0.9 # an axis value greater than this is considered 'fully pressed' in that direction

#TODO: probably want some kind of key repeat on next/prev weapon to cycle through lots of them

# _unhandled_input allows the GUI to process events first
func _unhandled_input(event):
	if event.device != config.gamepad_id:
			return

	if event is InputEventJoypadButton:
		var b = event.button_index
		if event.pressed:
			if jump_buttons.has(b):
				jump_pressed = true
			elif b == JOY_XBOX_X:
				inventory.cycle_selection(1)
			elif b == JOY_XBOX_Y:
				inventory.cycle_selection(-1)
			elif not auto_fire and b == JOY_R:
				fire_pressed = true

		else: # released
			if jump_buttons.has(b):
				jump_pressed = false
			elif not auto_fire and b == JOY_R:
				fire_pressed = false
				fire_held = false
	elif event is InputEventJoypadMotion:
		if event.axis == G.JoyAxis.LOOK_X:
			aim_direction.x = event.axis_value
			update_weapon_angle()
		elif event.axis == G.JoyAxis.LOOK_Y:
			aim_direction.y = event.axis_value
			update_weapon_angle()
		elif event.axis == G.JoyAxis.MOVE_X:
			move_direction = event.axis_value
			if abs(move_direction) < G.JOY_DEADZONE:
				move_direction = 0
		elif event.axis == G.JoyAxis.MOVE_Y:
			if event.axis_value > FULL_ON_THRESHOLD:
				try_fall_through()



func update_weapon_angle():
	if aim_direction.length() > G.JOY_DEADZONE: # only update when outside deadzone
		set_weapon_angle(aim_direction.angle())

func _process(delta):
	handle_auto_fire()

func handle_auto_fire():
	if not auto_fire:
		return

	var current_weapon = inventory.lock_current()
	if current_weapon != null and aim_direction.length() > FULL_ON_THRESHOLD:
		if current_weapon.auto_fire or not fire_held and current_weapon.can_shoot:
			fire_pressed = true
			$AutoFireReset.set_wait_time(auto_fire_cooldown)
			$AutoFireReset.start()
	else:
		fire_pressed = false
		fire_held = false
	inventory.unlock_current()



func _on_AutoFireReset_timeout():
	fire_pressed = false
	fire_held = false
