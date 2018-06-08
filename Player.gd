extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php


const UP = Vector2(0, -1)
const BEFORE_START = -999 # ms
const GRAVITY = 40
const ACCELERATION = 3000
const MAX_SPEED = 600
const JUMP_SPEED = 800
const FRICTION_DECAY = 0.6
# when the user moves in the opposite direction to the current speed, decay the
# speed quickly. This avoid the character feeling 'floaty' (set to 1.0 to
# disable)
const REACTIVITY_DECAY = 0.5

var motion = Vector2(0, 0)
var double_jump_enabled = false

# to make the jumping feel better
var last_jump_ms = BEFORE_START # ms
var was_on_floor = false
var left_floor_ms = BEFORE_START # the last time the player left the floor in ms
const PREEMPTIVE_JUMP_TOLERANCE = 50 # ms
const EDGE_JUMP_TOLERANCE = 50 # ms

func _ready():
	pass

func _physics_process(delta):
	motion.y += GRAVITY

	# get the direction from user input
	var direction = 0
	if Input.is_action_pressed('ui_left'):
		direction += -1
	if Input.is_action_pressed('ui_right'):
		direction += 1

	# calculate the speed
	#motion.x = direction*MAX_SPEED
	motion.x += direction*ACCELERATION*delta
	if sign(motion.x) != sign(direction):
		motion.x *= REACTIVITY_DECAY
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	# able to register a jump if character just about to hit the floor
	if Input.is_action_just_pressed('ui_up'):
		last_jump_ms = OS.get_ticks_msec()

	var now = OS.get_ticks_msec()
	var want_jump = now - last_jump_ms < PREEMPTIVE_JUMP_TOLERANCE

	if is_on_floor():
		was_on_floor = true

		# jump
		if want_jump:
			motion.y -= JUMP_SPEED
			last_jump_ms = BEFORE_START

		# apply friction
		if direction == 0: # not moving left or right
			motion.x = lerp(motion.x, 0, FRICTION_DECAY)
	else:

		# able to jump shortly after falling from a platform
		if was_on_floor:
			left_floor_ms = now
			was_on_floor = false

		# jump
		if want_jump and now - left_floor_ms < EDGE_JUMP_TOLERANCE:
			motion.y -= JUMP_SPEED
			last_jump_ms = BEFORE_START

		# cancel jump in mid air
		if Input.is_action_just_released('ui_up'):
			# if still moving up, then stop moving up
			motion.y = max(motion.y, -JUMP_SPEED/5)

	# play the appropriate animations
	if motion.x == 0:
		$AnimatedSprite.play('idle')
	elif motion.x > 0:
		$AnimatedSprite.play('walk')
		$AnimatedSprite.flip_h = false
	elif motion.x < 0:
		$AnimatedSprite.play('walk')
		$AnimatedSprite.flip_h = true

	motion = move_and_slide(motion, UP)

