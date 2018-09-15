extends KinematicBody2D

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

onready var G = globals

## Groups ##
# 'players'
# 'damageable'  (must have a take_damage method)

## SIGNALS ##
signal die
signal hit
signal invuln_changed
signal weapon_equiped(node)
signal weapon_unequiped(name)
signal weapon_selected(node)


## VARIABLES ##
var config # globals.PlayerConfig
var camera = null # used for mouse input and camera shake
var bullet_parent = null # the node to spawn the bullets under
var nav = null # the navigation node for the map

var current_weapon = null
var inventory_lock = Mutex.new() # protects current_weapon and $Inventory

## INPUT VARIABLES ##
# these variables are set using whatever method is in control of the player
var _weapon_angle = 0 # set with set_weapon_angle()
var auto_aim = null # only active when an instance of res://Player/AutoAim.gd
# a value between -1 and 1 (0 => idle) to determine the direction to move in (left or right)
# with analog input this value may be a non-integer
var move_direction = 0
var fire_pressed = false # whether the fire button is pressed down
var fire_held = false # whether the fire button is held down

## health and damage
var max_health = 100
var health = 0
var invulnerable = false

## MOVEMENT VARIABLES ##
var UP = Vector2(0, -1)
var ACCELERATION = 3000 # horizontal acceleration
var MAX_SPEED = 600 # horizontal speed limit
var FRICTION_DECAY = 0.6
# when the user moves in the opposite direction to the current speed, decay the
# speed quickly. This avoid the character feeling 'floaty' (set to 1.0 to disable)
const REACTIVITY_DECAY = 0.5

var velocity = Vector2(0, 0) # current velocity

var knockback = null # knockback velocity vector

var jump_pressed = false
onready var jump_physics = preload('JumpPhysics.gd').new()


func init(config, camera, bullet_parent, nav):
	self.config = config
	self.camera = camera
	self.bullet_parent = bullet_parent
	self.nav = nav

func _ready():
	if config.control == G.Control.GAMEPAD:# or config.control == G.Control.KEYBOARD:
		auto_aim = preload('res://Player/AutoAim.gd').new(self)
	hide()

func _process(delta):
	if is_alive():
		inventory_lock.lock()
		if current_weapon != null:
			var angle = _weapon_angle if auto_aim == null else auto_aim.auto_aim(_weapon_angle)
			current_weapon.set_rotation(angle)

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
		if is_on_floor():
			$AnimatedSprite.play('idle' if velocity.x == 0 else 'run')
		else:
			$AnimatedSprite.play('jump' if velocity.y < 0 else 'fall')

		if velocity.x > 0:
			$AnimatedSprite.flip_h = false
		elif velocity.x < 0:
			$AnimatedSprite.flip_h = true

	else: # dead
		$AnimatedSprite.play('death')

	#var dd = G.get_scene().debug_draw
	#dd.add_vector(velocity, position, INF, 'vel_%s' % config.num)

func _physics_process(delta):
	#TODO: is_on_floor doesn't count for when a player is on top of another player, so cannot jump for example
	var on_floor = is_on_floor()

	# get the direction from user input
	if is_alive():
		# calculate the horizontal movement
		velocity.x += sign(move_direction)*ACCELERATION*delta
		var max_speed = abs(move_direction)*MAX_SPEED
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
		if sign(velocity.x) != sign(move_direction):
			velocity.x *= REACTIVITY_DECAY
		if on_floor and move_direction == 0: # not moving left or right
			# apply friction (not physics-based friction, but something that works a bit like it)
			velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)

		velocity.y = jump_physics.advance_time_step(velocity.y, delta, jump_pressed, on_floor)

		# apply knockback
		if knockback != null:
			if on_floor:
				knockback.x += 3000 * sign(-knockback.x) * delta # friction
				knockback.y = clamp(knockback.y, -INF, 0) # sticking to the floor is handled by the main velocity, allow upwards velocity
			else:
				knockback += Vector2(0, jump_physics.GRAVITY) * delta
			knockback = Vector2(clamp(knockback.x, -MAX_SPEED, MAX_SPEED), clamp(knockback.y, -jump_physics.MAX_SPEED, jump_physics.MAX_SPEED))
			knockback = move_and_slide(knockback, UP)
			var dd = G.get_scene().debug_draw
			dd.add_vector(knockback, position, INF, 'knock_%s' % config.num)
			if knockback.length() < 100:
				knockback = null
	else:
		# dead
		if on_floor:
			velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)
			velocity.y = 100 # apply a small downwards force to remain on_floor
		else:
			velocity.y += jump_physics.GRAVITY * delta
			velocity.y = clamp(velocity.y, -jump_physics.MAX_SPEED, jump_physics.MAX_SPEED)

	velocity = move_and_slide(velocity, UP)


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
		gun.setup(self, bullet_parent)
		gun.connect('fired', self, '_on_weapon_fired')
		$Inventory.add_child(gun)
		emit_signal('weapon_equiped', gun)
	inventory_lock.unlock()

func select_weapon(name):
	if is_dead():
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
	if is_dead():
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

# pos is relative
func aim_at(pos):
	# maths copied from power defence
	if current_weapon != null:
		var gun_pos = current_weapon.get_position()
		var d = (pos - gun_pos).length()
		if abs(d) > 4: # pixels
			var angle = pos.angle_to_point(gun_pos)
			var muzzle_pos = current_weapon.get_node('Muzzle').get_position()
			var o = (muzzle_pos - gun_pos).y
			# cannot accurately aim at something closer than the muzzle
			if d > muzzle_pos.length():
				var angle_correction = asin(o/d)
				if abs(angle+angle_correction) > PI/2:
					angle += angle_correction
				else:
					angle -= angle_correction
			return angle
	return pos.angle()

func set_weapon_angle(angle):
	# _weapon_angle should always be set atomically, ie use a temporary variable
	# and set once at the end otherwise the aiming becomes jittery. This
	# function should deter direct access when writing (reading is OK).
	_weapon_angle = angle


func take_damage(damage, knockback):
	if invulnerable or is_dead():
		return
	var old_health = health
	emit_signal('hit')
	_set_health(health - damage)

	if self.knockback == null:
		self.knockback = knockback
	else:
		self.knockback += knockback

	if old_health > 0 and health <= 0:
		die()

func is_alive():
	return health > 0
func is_dead():
	return health <= 0

func _set_health(new_health):
	health = max(new_health, 0)
	$HealthBar.set_health(float(health)/max_health)

func _set_invulnerable(new_invuln):
	invulnerable = new_invuln
	if invulnerable:
		$InvulnTimer.start()
	$HealthBar.set_invulnerable(invulnerable)
	emit_signal('invuln_changed')

func die():
	if invulnerable:
		return
	_set_health(0)
	collision_layer = 0 # no longer on the players layer
	collision_mask = G.Layers.MAP # only collide with the map, not other players
	$BulletCollider.collision_layer = 0 # no longer collide with projectiles
	emit_signal('die')

#TODO: this should probably be handled in the gameplay code
func spawn(position):
	_set_invulnerable(true)
	self.position = position
	collision_layer = G.Layers.PLAYERS
	collision_mask = G.Layers.PLAYERS | G.Layers.MAP
	$BulletCollider.collision_layer = G.Layers.BULLET_COLLIDERS
	_set_health(max_health)

	_clear_inventory()
	equip_weapon(G.pickups['Pistol'].scene.instance())
	select_weapon('Pistol')
	show()

func teleport(location):
	global_position = location
	velocity = Vector2(0, 0)
	move_direction = 0
	knockback = null
	jump_pressed = false
	jump_physics.reset()


func delayed_spawn(position):
	if $SpawnTimer.is_stopped(): # if timer already going, don't restart
		$SpawnTimer.connect('timeout', self, 'spawn', [position], CONNECT_ONESHOT)
		$SpawnTimer.start()

func _on_InvulnTimer_timeout():
	_set_invulnerable(false)

func _on_weapon_fired(bullets):
	camera.shake(current_weapon.screen_shake)
	if config.control == G.Control.GAMEPAD:
		Input.start_joy_vibration(config.gamepad_id, 0.8, 0.8, 0.5)

