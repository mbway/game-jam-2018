extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

## SIGNALS ##
signal die
signal hit

## CONSTANTS ##
const UP = Vector2(0, -1)
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

## health and damage
var health = 0
var alive = false
var invulnerable = false

## weapons
var weapons = []


## MOVEMENT ##
const GRAVITY = 40
const ACCELERATION = 3000
const MAX_SPEED = 600
const JUMP_SPEED = 1000
const FRICTION_DECAY = 0.6
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

func setup(input_prefix, max_health, bullet_parent, camera, mouse_look):
	self.input_prefix = input_prefix
	self.max_health = max_health
	self.bullet_parent = bullet_parent
	self.camera = camera
	self.mouse_look = mouse_look
	#TODO: give pistol
	is_setup = true

func _process(delta):
	if not is_setup:
		return

	if alive and has_node('Gun'):
		# gun rotation
		var angle = 0
		var angle_correction = 0

		if mouse_look:
			# mouse
			# maths copied from power defence
			var gun_pos = $Gun.get_position()
			var mouse_pos = get_local_mouse_position()
			angle = mouse_pos.angle_to_point(gun_pos)
			var d = (mouse_pos - gun_pos).length()
			var o = ($Gun/Muzzle.get_position()-gun_pos).y
			angle_correction = asin(o/d)
		else:
			# gamepad
			var direction = Vector2(Input.get_joy_axis(0, JOY_X), Input.get_joy_axis(0, JOY_Y))
			if direction.length() > JOY_DEADZONE:
				angle = direction.angle()
			else:
				angle = $Gun.rotation

		if abs(angle) > PI/2:
			$Gun.scale.y = -1
			angle += angle_correction
		else:
			$Gun.scale.y = 1
			angle -= angle_correction
		$Gun.set_rotation(angle)

		# gun firing
		var pressed = Input.is_action_pressed(input_prefix + 'fire')
		var just_pressed = Input.is_action_just_pressed(input_prefix + 'fire')
		var fired = $Gun.try_shoot(pressed, just_pressed)
		if fired:
			camera.shake($Gun.screen_shake)


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

func equip(gun):
	weapons.append(gun)
	gun.set_name('Gun')
	gun.setup(bullet_parent)
	add_child(gun)

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
	layers = 1 # collide with map and bullets
	$InvulnTimer.start()
	self.position = position
	_set_health(max_health)
	alive = true

func _on_InvulnTimer_timeout():
	invulnerable = false
