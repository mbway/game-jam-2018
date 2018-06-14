extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

var globals
onready var pistol_scene = preload('res://Weapons/Pistol.tscn')

## SIGNALS ##
signal die
signal hit
signal weapon_equiped(Node)
signal weapon_selected(Node)

## CONSTANTS ##
const BEFORE_START = -999 # timestamp long before the start of the game (ms)


# set when spawned in
var is_setup = false
var camera = null # used for mouse input and camera shake
var bullet_parent = null # the node to spawn the bullets under
var config # globals.PlayerConfig

var current_weapon = null
var inventory_lock = Mutex.new() # protects current_weapon and $Inventory

## health and damage
var max_health = 100
var health = 0
var alive = false
var invulnerable = false


var fire_pressed = false
var fire_held = false

## MOVEMENT ##
var UP = Vector2(0, -1)
var GRAVITY = 40
var ACCELERATION = 3000
var MAX_SPEED = 600
var JUMP_SPEED = 1000
var FRICTION_DECAY = 0.6
# when the user moves in the opposite direction to the current speed, decay the
# speed quickly. This avoid the character feeling 'floaty' (set to 1.0 to
# disable)
const REACTIVITY_DECAY = 0.5

var velocity = Vector2(0, 0) # current velocity

# mechanisms to make the jumping feel better
const PREEMPTIVE_JUMP_TOLERANCE = 50 # ms
const EDGE_JUMP_TOLERANCE = 50 # ms
var last_jump_ms = BEFORE_START # ms
var jump_released = false # able to cancel jump early by releasing the jump button
var was_on_floor = false # was on the floor last physics update
var left_floor_ms = BEFORE_START # the last time the player left the floor in ms

# double jumping #
const MAX_ADDITIONAL_JUMPS = 1
var additional_jumps_left = 1 # to allow double jumps, reset when touching the floor


func _ready():
	globals = get_node('/root/globals')
	hide()

func setup(config, bullet_parent, camera):
	self.config = config
	self.bullet_parent = bullet_parent
	self.camera = camera
	is_setup = true

func _process(delta):
	if not is_setup:
		return

	inventory_lock.lock()
	if alive and current_weapon != null:
		# gun rotation
		var angle = get_weapon_angle()
		
		if abs(angle) > PI/2:
			current_weapon.scale.y = -1
		else:
			current_weapon.scale.y = 1
		
		current_weapon.set_rotation(angle)
		
		if fire_pressed:
			current_weapon.try_shoot(fire_held)
			fire_held = true
	inventory_lock.unlock()
	
	
	# play the appropriate animation
	if alive:
		if is_on_floor():
			if velocity.x == 0:
				$AnimatedSprite.play('idle')
			else:
				$AnimatedSprite.play('run')
		else:
			if velocity.y < 0:
				$AnimatedSprite.play('jump')
			else:
				$AnimatedSprite.play('fall')
	else:
		$AnimatedSprite.play('death')

	if velocity.x > 0:
		$AnimatedSprite.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite.flip_h = true


func _physics_process(delta):
	if not is_setup:
		return

	velocity.y += GRAVITY

	var now = OS.get_ticks_msec()
	var on_floor = is_on_floor()

	# get the direction from user input
	if alive:
		# [-1,1], may be non-integer if analog control
		var direction = get_move_direction()

		# calculate the speed
		#velocity.x = direction*MAX_SPEED
		velocity.x += sign(direction)*ACCELERATION*delta
		if sign(velocity.x) != sign(direction):
			velocity.x *= REACTIVITY_DECAY
		var max_speed = abs(direction)*MAX_SPEED
		velocity.x = clamp(velocity.x, -max_speed, max_speed)

		# able to register a jump if character just about to hit the floor
		if now - last_jump_ms < PREEMPTIVE_JUMP_TOLERANCE: # want to jump
			if on_floor:
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
			elif now - left_floor_ms < EDGE_JUMP_TOLERANCE:
				# able to jump shortly after falling from a platform
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
			elif additional_jumps_left > 0:
				# ensure that the current jump is canceled. with more than
				# one button assigned to jump it is possible to trigger
				# the double jump without releasing the first
				velocity.y = max(velocity.y, -JUMP_SPEED/5)
				
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
				additional_jumps_left -= 1

		if on_floor:
			#TODO: maybe try and check that we aren't standing on a bullet
			additional_jumps_left = MAX_ADDITIONAL_JUMPS # reset double jump
			
			# apply friction
			if direction == 0: # not moving left or right
				velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)
		else:
			# able to jump shortly after falling from a platform
			if was_on_floor:
				left_floor_ms = now

			# cancel jump in mid air
			if jump_released:
				# if still moving up, then stop moving up
				velocity.y = max(velocity.y, -JUMP_SPEED/5)

	else:
		# dead
		if on_floor:
			velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)

	was_on_floor = on_floor
	velocity = move_and_slide(velocity, UP)

	
func _input(event):
	# mouse wheel events have to be handled specially :(
	# this is apparently because they are more short-lived
	if config.control == globals.KEYBOARD_CONTROL:
		# mouse scroll to switch weapons
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					select_next_weapon(-1)
				elif event.button_index == BUTTON_WHEEL_DOWN:
					select_next_weapon(1)
				elif event.button_index == BUTTON_LEFT:
					fire_pressed = true
			else:
				if event.button_index == BUTTON_LEFT:
					fire_pressed = false
					fire_held = false
		
		elif event is InputEventKey:
			if event.pressed and not event.is_echo(): # disregard key repeats
				if event.scancode == KEY_W or event.scancode == KEY_SPACE:
					try_jump()
			elif not event.pressed: # released
				if event.scancode == KEY_W or event.scancode == KEY_SPACE:
					jump_released = true
	
					
	elif config.control == globals.GAMEPAD_CONTROL:
		if event is InputEventJoypadButton:
			if event.pressed:
				if event.button_index == JOY_XBOX_A or event.button_index == JOY_L:
					try_jump()
				elif event.button_index == JOY_XBOX_X:
					select_next_weapon(1)
				elif event.button_index == JOY_XBOX_Y:
					select_next_weapon(-1)
				elif event.button_index == JOY_R:
					fire_pressed = true
						
			else: # released
				if event.button_index == JOY_XBOX_A or event.button_index == JOY_L:
					jump_released = true
				elif event.button_index == JOY_R:
					fire_pressed = false
					fire_held = false
				
func try_jump():
	last_jump_ms = OS.get_ticks_msec() # want to jump
	jump_released = false
	

# returns a value between -1 and 1 (0 => idle) to determine the direction to move in (left or right)
# with gamepad input this value may be a non-integer value
func get_move_direction():
	var direction = 0
	if config.control == globals.KEYBOARD_CONTROL:
		if Input.is_key_pressed(KEY_A):
			direction += -1
		if Input.is_key_pressed(KEY_D):
			direction += 1
	elif config.control == globals.GAMEPAD_CONTROL:
		direction = Input.get_joy_axis(config.gamepad_id, globals.JOY_MOVE_X)
		if abs(direction) < globals.JOY_DEADZONE:
			direction = 0
			if Input.is_joy_button_pressed(config.gamepad_id, JOY_DPAD_LEFT):
				direction += -1
			if Input.is_joy_button_pressed(config.gamepad_id, JOY_DPAD_RIGHT):
				direction += 1
	else:
		print('not implemented')
	return direction

func get_weapon_angle():
	var angle = 0

	if config.control == globals.KEYBOARD_CONTROL:
		# mouse
		# maths copied from power defence
		var gun_pos = current_weapon.get_position()
		var mouse_pos = get_local_mouse_position()
		angle = mouse_pos.angle_to_point(gun_pos)
		var d = (mouse_pos - gun_pos).length()
		var o = (current_weapon.get_node('Muzzle').get_position()-gun_pos).y
		if d != 0:
			var angle_correction = asin(o/d)
			if abs(angle) > PI/2:
				angle += angle_correction
			else:
				angle -= angle_correction
			
	elif config.control == globals.GAMEPAD_CONTROL:
		# gamepad
		var x = Input.get_joy_axis(config.gamepad_id, globals.JOY_LOOK_X)
		var y = Input.get_joy_axis(config.gamepad_id, globals.JOY_LOOK_Y)
		var direction = Vector2(x, y)
		if direction.length() > globals.JOY_DEADZONE:
			angle = direction.angle()
		else:
			angle = current_weapon.rotation
	else:
		print('not implemented')
	
	return angle


func _clear_inventory():
	inventory_lock.lock()
	current_weapon = null
	for w in $Inventory.get_children():
		w.free() # queue_free here causes crashes
	inventory_lock.unlock()
	
func equip_weapon(gun):
	inventory_lock.lock()
	if $Inventory.has_node(gun.name):
		print('player already has weapon: %s' % gun.name)
	else:
		gun.setup(bullet_parent)
		gun.connect('fired', self, '_on_weapon_fired')
		$Inventory.add_child(gun)
		emit_signal('weapon_equiped', gun)
	inventory_lock.unlock()
	
func select_weapon(name):
	inventory_lock.lock()
	if current_weapon != null:
		current_weapon.set_active(false)
	elif $Inventory.has_node(name):
		current_weapon = $Inventory.get_node(name)
		current_weapon.set_active(true)
	else:
		print('player does not have weapon: %s' % name)
	inventory_lock.unlock()
	emit_signal('weapon_selected', name)
		
# offset = 1 for next, -1 for prev
func select_next_weapon(offset):
	inventory_lock.lock()
	var n = $Inventory.get_child_count()
	if current_weapon != null and n > 0:
		current_weapon.set_active(false)
	
		var i = current_weapon.get_index() + offset
		if i < 0:
			i += n
		i = i % n
		
		current_weapon = $Inventory.get_child(i)
		current_weapon.set_active(true)
	inventory_lock.unlock()
	if current_weapon != null:
		emit_signal('weapon_selected', current_weapon.name)

func take_damage(damage):
	if invulnerable:
		return
	var new_health = max(health - damage, 0)
	emit_signal('hit')
	_set_health(new_health)
	if alive and health <= 0:
		die()

func _set_health(new_health):
	health = max(new_health, 0)
	$HealthBar.set_health(float(health)/max_health)

func die():
	if invulnerable:
		return
	alive = false
	layers = 2 # collide with map but not with bullets
	emit_signal('die')

func spawn(position):
	show()
	invulnerable = true
	$InvulnTimer.start()
	
	_clear_inventory()
	equip_weapon(pistol_scene.instance())
	select_weapon('Pistol')
	
	layers = 1 # collide with map and bullets
	self.position = position
	_set_health(max_health)
	alive = true

func delayed_spawn(position):
	$SpawnTimer.connect('timeout', self, 'spawn', [position], CONNECT_ONESHOT)
	$SpawnTimer.start()

func _on_InvulnTimer_timeout():
	invulnerable = false

func _on_weapon_fired():
	camera.shake(current_weapon.screen_shake)
	if config.control == globals.GAMEPAD_CONTROL:
		Input.start_joy_vibration(config.gamepad_id, 0.8, 0.8, 0.5)
