extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

onready var G = globals
onready var pistol_scene = preload('res://Weapons/Pistol.tscn')

## Groups ##
# 'players'
# 'damageable'  (must have a take_damage method)

## SIGNALS ##
signal die
signal hit
signal weapon_equiped(node)
signal weapon_unequiped(name)
signal weapon_selected(node)


## CONSTANTS ##
const BEFORE_START = -999 # timestamp long before the start of the game (ms)


## VARIABLES ##
var config # globals.PlayerConfig
var camera = null # used for mouse input and camera shake
var bullet_parent = null # the node to spawn the bullets under
var nav = null # the navigation polygon


var current_weapon = null
var inventory_lock = Mutex.new() # protects current_weapon and $Inventory

## INPUT VARIABLES ##
# these variables are set using whatever method is in control of the player
var weapon_angle = 0 # TODO
# a value between -1 and 1 (0 => idle) to determine the direction to move in (left or right)
# with analog input this value may be a non-integer
var move_direction = 0
var fire_pressed = false # whether the fire button is pressed down
var fire_held = false # whether the fire button is held down
# use try_jump() to initiate a jump and set jump_released to false to cancel it
var last_jump_pressed_ms = BEFORE_START # ms. Time at which the jump button was last pressed. Don't set directly, use try_jump instead
var jump_released = false # able to cancel jump early by releasing the jump button


## health and damage
var max_health = 100
var health = 0
var alive = false
var invulnerable = false

## MOVEMENT VARIABLES ##
var UP = Vector2(0, -1)
var GRAVITY = 40
var ACCELERATION = 3000
var MAX_SPEED = 600
var JUMP_SPEED = 1000
var FRICTION_DECAY = 0.6
# when the user moves in the opposite direction to the current speed, decay the
# speed quickly. This avoid the character feeling 'floaty' (set to 1.0 to disable)
const REACTIVITY_DECAY = 0.5

var velocity = Vector2(0, 0) # current velocity

# mechanisms to make the jumping feel better
const PREEMPTIVE_JUMP_TOLERANCE = 50 # ms
const EDGE_JUMP_TOLERANCE = 100 # ms
var last_jump_ms = BEFORE_START # ms. Time at which the last jump occurred (different from last_jump_pressed_ms)
var was_on_floor = false # whether the player was in contact with the floor on the last physics update
var left_floor_ms = BEFORE_START # the last time the player left the floor in ms

# double jumping #
const MAX_MID_AIR_JUMPS = 1
var mid_air_jumps = MAX_MID_AIR_JUMPS # used to allow double jumps. Reset when touching the floor


func init(config, camera, bullet_parent, nav):
	self.config = config
	self.camera = camera
	self.bullet_parent = bullet_parent
	self.nav = nav

func _ready():
	hide()


func _process(delta):
	inventory_lock.lock()
	if alive and current_weapon != null:
		current_weapon.set_rotation(weapon_angle)

		# gun rotation
		# the small margin is to prevent the gun from flickering when aiming directly up
		if abs(current_weapon.rotation) > PI/2 + 0.01:
			current_weapon.scale.y = -1
		else:
			current_weapon.scale.y = 1

		if fire_pressed:
			current_weapon.try_shoot(fire_held)
			fire_held = true
	inventory_lock.unlock()


	# play the appropriate animation
	if alive:
		if is_on_floor():
			$AnimatedSprite.play('idle' if velocity.x == 0 else 'run')
		else:
			$AnimatedSprite.play('jump' if velocity.y < 0 else 'fall')
	else:
		$AnimatedSprite.play('death')

	if velocity.x > 0:
		$AnimatedSprite.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite.flip_h = true


func _physics_process(delta):
	velocity.y += GRAVITY

	var now = OS.get_ticks_msec()
	var on_floor = is_on_floor()

	# get the direction from user input
	if alive:
		# calculate the speed
		velocity.x += sign(move_direction)*ACCELERATION*delta
		if sign(velocity.x) != sign(move_direction):
			velocity.x *= REACTIVITY_DECAY
		var max_speed = abs(move_direction)*MAX_SPEED
		velocity.x = clamp(velocity.x, -max_speed, max_speed)

		# handle jumping
		# able to register a jump if character just about to hit the floor
		if now - last_jump_pressed_ms < PREEMPTIVE_JUMP_TOLERANCE and not jump_released: # want to jump
			if on_floor:
				# if on the floor then jump
				# if preemptively pressed: initiate jump once on the floor
				velocity.y -= JUMP_SPEED
				last_jump_pressed_ms = BEFORE_START
				last_jump_ms = now

			elif now - left_floor_ms < EDGE_JUMP_TOLERANCE:
				# able to jump shortly after falling from a platform
				velocity.y -= JUMP_SPEED
				last_jump_pressed_ms = BEFORE_START
				last_jump_ms = now

			elif mid_air_jumps > 0:
				# ensure that the current jump is cancelled. With more than
				# one button assigned to jump it is possible to trigger
				# the double jump without releasing the first
				velocity.y = max(velocity.y, -JUMP_SPEED/5)

				velocity.y -= JUMP_SPEED
				last_jump_pressed_ms = BEFORE_START
				mid_air_jumps -= 1
				last_jump_ms = now

		if on_floor:
			mid_air_jumps = MAX_MID_AIR_JUMPS

			# apply friction
			if move_direction == 0: # not moving left or right
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

func try_jump():
	last_jump_pressed_ms = OS.get_ticks_msec() # want to jump
	jump_released = false


func _clear_inventory():
	inventory_lock.lock()
	current_weapon = null
	for w in $Inventory.get_children():
		emit_signal('weapon_unequiped', w.name)
		w.free() # queue_free here causes crashes
	inventory_lock.unlock()

func equip_weapon(gun):
	inventory_lock.lock()
	if $Inventory.has_node(gun.name):
		G.log_err('player already has weapon: %s' % gun.name)
	else:
		gun.setup(bullet_parent)
		gun.connect('fired', self, '_on_weapon_fired')
		$Inventory.add_child(gun)
		emit_signal('weapon_equiped', gun)
	inventory_lock.unlock()

func select_weapon(name):
	if not alive:
		return
	inventory_lock.lock()
	if current_weapon != null:
		current_weapon.set_active(false)
	elif $Inventory.has_node(name):
		current_weapon = $Inventory.get_node(name)
		current_weapon.set_active(true)
	else:
		G.log_err('player does not have weapon: %s' % name)
	inventory_lock.unlock()
	emit_signal('weapon_selected', name)

# offset = 1 for next, -1 for prev
func select_next_weapon(offset):
	if not alive:
		return
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
	if invulnerable or not alive:
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
	_set_health(0)
	alive = false
	emit_signal('die')

#TODO: this should probably be handled in the gameplay code
func spawn(position):
	show()
	invulnerable = true
	$InvulnTimer.start()

	self.position = position
	_set_health(max_health)
	alive = true

	_clear_inventory()
	equip_weapon(pistol_scene.instance())
	select_weapon('Pistol')


func delayed_spawn(position):
	if $SpawnTimer.is_stopped(): # if timer already going, don't restart
		$SpawnTimer.connect('timeout', self, 'spawn', [position], CONNECT_ONESHOT)
		$SpawnTimer.start()

func _on_InvulnTimer_timeout():
	invulnerable = false

func _on_weapon_fired(bullets):
	camera.shake(current_weapon.screen_shake)
	if config.control == G.GAMEPAD_CONTROL:
		Input.start_joy_vibration(config.gamepad_id, 0.8, 0.8, 0.5)

	for b in bullets:
		b.add_collision_exception($BulletCollider)
