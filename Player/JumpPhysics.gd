
enum State {
	FLOOR,			# the player is touching the floor.
	EDGE_PLATFORM,	# the player has recently fallen from a platform. Is able to jump from this state as if it was still on the floor.
	JUMPING,		# a jump is in progress, the jump button is held.
	JUMP_FINISHED,	# when the player hits the floor before releasing the jump button. Must release before performing another jump.
	FALLING,		# not on the floor but jump is not pressed, can jump from this state if there are mid_air_jumps available.
	PREEMPTIVE_JUMP	# can initiate a jump in mid-air (shortly before hitting the floor) which will register once the ground is hit.
}
var state = State.FLOOR
var time_in_state = 0 # seconds
var vel = 0

const GRAVITY = 2400 # acceleration due to gravity
const MAX_SPEED = 2000 # clamp the speed if it exceeds this value (in either direction)
const JUMP_SPEED = 1000 # the speed 'impulse' to apply when triggering a jump
const RELEASE_SPEED = JUMP_SPEED/5 # the maximum upwards velocity after cancelling a jump in mid air
const PREEMPTIVE_JUMP_TOLERANCE = 50 / 1000.0 # (seconds) the time before hitting the floor in which a 'preemptive jump' can be performed
const EDGE_JUMP_TOLERANCE = 100 / 1000.0 # (seconds) the time after leaving the floor in which an 'edge jump' can be performed

# double jumping #
const MAX_MID_AIR_JUMPS = 1
var mid_air_jumps = MAX_MID_AIR_JUMPS # used to allow double jumps. Reset when touching the floor.


func advance_time_step(last_vel, delta, jump_pressed, on_floor):
	vel = last_vel
	time_in_state += delta
	handle_transitions(jump_pressed, on_floor)

	if state == State.FLOOR:
		# when on the floor, move_and_slide results in an exactly 0 vertical
		# velocity after correction, however for move_and_slide to register that
		# the player is on the ground, a sufficient downwards velocity (force)
		# must be applied. If GRAVITY is too low, or the game speed (timescale)
		# is set too low then applying GRAVITY*delta each tick is not sufficient
		# to 'stick' to the ground, causing the player to float over the ground
		# and glitch every now and then. Since this will be corrected to 0
		# anyway, an arbitrary downwards velocity is chosen.
		vel = 100 # positive is downwards
	else:
		vel += GRAVITY * delta
		vel = clamp(vel, -MAX_SPEED, MAX_SPEED)
	return vel

func handle_transitions(jump_pressed, on_floor):
	if state == State.FLOOR:
		if jump_pressed:
			transition(State.JUMPING)
		elif not on_floor:
			transition(State.EDGE_PLATFORM)

	elif state == State.EDGE_PLATFORM:
		if jump_pressed:
			transition(State.JUMPING)
		elif on_floor:
			transition(State.FLOOR)
		elif time_in_state > EDGE_JUMP_TOLERANCE:
			transition(State.FALLING)

	elif state == State.FALLING:
		if on_floor:
			transition(State.FLOOR)
		elif jump_pressed:
			if mid_air_jumps > 0:
				transition(State.JUMPING)
			else:
				transition(State.PREEMPTIVE_JUMP)

	elif state == State.JUMPING:
		if not jump_pressed:
			transition(State.FALLING)
		elif on_floor:
			transition(State.JUMP_FINISHED)

	elif state == State.JUMP_FINISHED:
		if not jump_pressed:
			if on_floor:
				transition(State.FLOOR)
			else:
				transition(State.FALLING)

	elif state == State.PREEMPTIVE_JUMP:
		if on_floor:
			transition(State.JUMPING)
		elif time_in_state > PREEMPTIVE_JUMP_TOLERANCE:
			transition(State.JUMP_FINISHED)

# transition to a state and perform any actions associated with a transition or entering a state
func transition(to):
	var from = state

	# transition actions
	if from == State.FALLING and to == State.JUMPING:
		assert mid_air_jumps > 0
		mid_air_jumps -= 1
	elif from == State.PREEMPTIVE_JUMP and to == State.JUMPING:
		mid_air_jumps = MAX_MID_AIR_JUMPS
	elif from == State.JUMPING and to == State.FALLING:
		vel = clamp(vel, -RELEASE_SPEED, MAX_SPEED)
		

	# enter state actions
	if to == State.FLOOR:
		mid_air_jumps = MAX_MID_AIR_JUMPS
	elif to == State.JUMPING:
		vel = -JUMP_SPEED

	state = to
	time_in_state = 0

	#print(state_name(from), '->', state_name(to))
	#print(state_name(state))
	#if from == State.EDGE_PLATFORM and to == State.JUMPING:
		#print('edge jump')
	#if from == State.PREEMPTIVE_JUMP and to == State.JUMPING:
		#print('preemptive jump')

# whether releasing the jump button would 
func is_past_jump_peak():
	if state == State.JUMPING:
		return bool(vel > -RELEASE_SPEED) # negative is upwards
	else:
		return true # question doesn't make sense in some states but this is still a somewhat sensible answer

func state_name(state):
	if state == State.FLOOR:
		return 'FLOOR'
	elif state == State.EDGE_PLATFORM:
		return 'EDGE_PLATFORM'
	elif state == State.JUMPING:
		return 'JUMPING'
	elif state == State.JUMP_FINISHED:
		return 'JUMP_FINISHED'
	elif state == State.FALLING:
		return 'FALLING'
	elif state == State.PREEMPTIVE_JUMP:
		return 'PREEMPTIVE_JUMP'
	else:
		return 'invalid state'

