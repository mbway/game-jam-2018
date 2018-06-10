extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

## SIGNALS ##
signal die
signal hit
signal weapon_equiped(Node)
signal weapon_selected(Node)

## CONSTANTS ##
var UP = Vector2(0, -1)
const BEFORE_START = -999 # timestamp long before the start of the game (ms)
const JOY_X = 2
const JOY_Y = 3
const JOY_DEADZONE = 0.2

onready var pistol_scene = load('res://Weapons/Pistol.tscn')

# set when spawned in
var is_setup = false
var input_prefix = null # eg 'p1_' for player 1
var camera = null # used for mouse input
var mouse_look = true # whether to use the mouse for looking around (false => gamepad)
var bullet_parent = null # the node to spawn the bullets under
var max_health = 100

var current_weapon = null
var inventory_lock = Mutex.new() # protects current_weapon and $Inventory
var team

## health and damage
var health = 0
var alive = false
var invulnerable = false



## MOVEMENT ##
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
var was_on_floor = false # was on the floor last physics update
var left_floor_ms = BEFORE_START # the last time the player left the floor in ms

# double jumping #
const MAX_ADDITIONAL_JUMPS = 1
var additional_jumps_left = 1 # to allow double jumps, reset when touching the floor

func _ready():
	hide()

func setup(input_prefix, max_health, bullet_parent, camera, mouse_look, team):
	self.input_prefix = input_prefix
	self.max_health = max_health
	self.bullet_parent = bullet_parent
	self.camera = camera
	self.mouse_look = mouse_look
	self.team = team
	#TODO: give pistol
	is_setup = true

func _process(delta):
	if not is_setup:
		return

	inventory_lock.lock()
	if alive and current_weapon != null:
		# gun rotation
		var angle = 0
		var angle_correction = 0

		if mouse_look:
			# mouse
			# maths copied from power defence
			var gun_pos = current_weapon.get_position()
			var mouse_pos = get_local_mouse_position()
			angle = mouse_pos.angle_to_point(gun_pos)
			var d = (mouse_pos - gun_pos).length()
			var o = (current_weapon.get_node('Muzzle').get_position()-gun_pos).y
			angle_correction = asin(o/d)
		else:
			# gamepad
			var direction = Vector2(Input.get_joy_axis(0, JOY_X), Input.get_joy_axis(0, JOY_Y))
			if direction.length() > JOY_DEADZONE:
				angle = direction.angle()
			else:
				angle = current_weapon.rotation

		if abs(angle) > PI/2:
			current_weapon.scale.y = -1
			angle += angle_correction
		else:
			current_weapon.scale.y = 1
			angle -= angle_correction
		current_weapon.set_rotation(angle)

		# gun firing
		var pressed = Input.is_action_pressed(input_prefix + 'fire')
		var just_pressed = Input.is_action_just_pressed(input_prefix + 'fire')
		var fired = current_weapon.try_shoot(pressed, just_pressed, delta)
		if fired:
			camera.shake(current_weapon.screen_shake)
	
		# weapon selecting
		if Input.is_action_just_pressed(input_prefix + 'next'):
			select_next_weapon(1)
		if Input.is_action_just_pressed(input_prefix + 'prev'):
			select_next_weapon(-1)
	inventory_lock.unlock()
	
func _input(event):
	# mouse wheel events have to be handled specially :(
	# this is apparently because they are more short-lived
	if mouse_look and event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			select_next_weapon(-1)
		if event.button_index == BUTTON_WHEEL_DOWN:
			select_next_weapon(1)

func _physics_process(delta):
	if not is_setup:
		return

	velocity.y += GRAVITY

	var now = OS.get_ticks_msec()
	var on_floor = is_on_floor()

	# get the direction from user input
	if alive:
		var direction = 0
		if Input.is_action_pressed(input_prefix + 'left'):
			direction += -1
		if Input.is_action_pressed(input_prefix + 'right'):
			direction += 1

		# calculate the speed
		#velocity.x = direction*MAX_SPEED
		velocity.x += direction*ACCELERATION*delta
		if sign(velocity.x) != sign(direction):
			velocity.x *= REACTIVITY_DECAY
		velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

		# able to register a jump if character just about to hit the floor
		if Input.is_action_just_pressed(input_prefix + 'up'):
			last_jump_ms = now

		if now - last_jump_ms < PREEMPTIVE_JUMP_TOLERANCE: # want to jump
			if on_floor:
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
			elif now - left_floor_ms < EDGE_JUMP_TOLERANCE:
				# able to jump shortly after falling from a platform
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
			elif additional_jumps_left > 0:
				velocity.y -= JUMP_SPEED
				last_jump_ms = BEFORE_START
				additional_jumps_left -= 1

		if on_floor:
			additional_jumps_left = MAX_ADDITIONAL_JUMPS
			# apply friction
			if direction == 0: # not moving left or right
				velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)
		else:
			# able to jump shortly after falling from a platform
			if was_on_floor:
				left_floor_ms = now

			# cancel jump in mid air
			if Input.is_action_just_released(input_prefix + 'up'):
				# if still moving up, then stop moving up
				velocity.y = max(velocity.y, -JUMP_SPEED/5)

		was_on_floor = on_floor
	else:
		# dead
		if on_floor:
			velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)

	# play the appropriate animations
	if alive:
		if on_floor:
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

	velocity = move_and_slide(velocity, UP)

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
	if current_weapon != null:
		current_weapon.set_active(false)
	
	var n = $Inventory.get_child_count()
	var i = current_weapon.get_index() + offset
	if i < 0:
		i += n
	i = i % n
	
	current_weapon = $Inventory.get_child(i)
	current_weapon.set_active(true)
	inventory_lock.unlock()
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

func _on_InvulnTimer_timeout():
	invulnerable = false
