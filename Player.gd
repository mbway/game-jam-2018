extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

## CONSTANTS ##
const UP = Vector2(0, -1)
const BEFORE_START = -999 # timestamp long before the start of the game (ms)
const JOY_X = 2
const JOY_Y = 3
const JOY_DEADZONE = 0.2

# set when spawned in
var is_setup = false
var input_prefix = null
var camera = null # used for mouse input, null => 
var bullet_parent = null # the node to spawn the bullets under



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


func setup(input_prefix, bullet_parent, camera):
	self.input_prefix = input_prefix
	self.bullet_parent = bullet_parent
	self.camera = camera
	is_setup = true

func _process(delta):
	if not is_setup:
		return
		
	if has_node('Gun'):
		# gun rotation
		var angle = 0
		var angle_correction = 0
		
		if camera == null:
			# gamepad
			var direction = Vector2(Input.get_joy_axis(0, JOY_X), Input.get_joy_axis(0, JOY_Y))
			if direction.length() > JOY_DEADZONE:
				angle = direction.angle()
			else:
				angle = $Gun.rotation
		else:
			# mouse
			# maths copied from power defence
			var gun_pos = $Gun.get_position()
			var mouse_pos = camera.get_local_mouse_position()
			angle = mouse_pos.angle_to_point(gun_pos)
			var d = (mouse_pos - gun_pos).length()
			var o = ($Gun/Muzzle.get_position()-gun_pos).y
			angle_correction = asin(o/d)

		if abs(angle) > PI/2:
			$Gun.scale.y = -1
			angle += angle_correction
		else:
			$Gun.scale.y = 1
			angle -= angle_correction
		$Gun.set_rotation(angle)


func _physics_process(delta):
	if not is_setup:
		return
		
	velocity.y += GRAVITY

	# get the direction from user input
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

	var now = OS.get_ticks_msec()
	var on_floor = is_on_floor()

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

	# play the appropriate animations
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

	if velocity.x > 0:
		$AnimatedSprite.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite.flip_h = true

	velocity = move_and_slide(velocity, UP)

func equip(gun_scene):
	assert not has_node('Gun')
	var gun = gun_scene.instance()
	gun.set_name('Gun')
	gun.setup(bullet_parent, input_prefix + 'fire')
	add_child(gun)



