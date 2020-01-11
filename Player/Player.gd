extends KinematicBody2D
class_name Player

# This blog post was very useful for determining how to make the movement feel better
# https://www.gamasutra.com/blogs/YoannPignole/20140103/207987/Platformer_controls_how_to_avoid_limpness_and_rigidity_feelings.php

onready var G = globals
const DiGraph2D = preload('res://addons/graph_node/src/DiGraph2D.gd')

## Groups ##
# 'players'
# 'damageable'  (must have a take_damage method)

## SIGNALS ##
signal die
signal hit
signal invuln_changed


## VARIABLES ##
var config # globals.PlayerConfig

var camera: Camera2D # used for mouse input and camera shake
var bullet_parent: Node2D # the node to spawn the bullets under
var nav: DiGraph2D # the navigation node for the map

## INPUT VARIABLES ##
# these variables are set using whatever method is in control of the player
var _weapon_angle := 0.0 # set with set_weapon_angle()
var auto_aim = null # only active when an instance of res://Player/AutoAim.gd
# a value between -1 and 1 (0 => idle) to determine the direction to move in (left or right)
# with analog input this value may be a non-integer
var move_direction := 0
var fire_pressed := false # whether the fire button is pressed down
var fire_held := false # whether the fire button is held down

## health and damage
var max_health := 100.0
var health := 0.0
var invulnerable := false

## MOVEMENT VARIABLES ##
var UP := Vector2(0, -1)
var ACCELERATION := 3000.0 # horizontal acceleration
var MAX_SPEED := 600.0 # horizontal speed limit
var FRICTION_DECAY := 0.6
# when the user moves in the opposite direction to the current speed, decay the
# speed quickly. This avoid the character feeling 'floaty' (set to 1.0 to disable)
const REACTIVITY_DECAY := 0.5

var velocity := Vector2(0, 0) # current velocity

var knockback = null # knockback velocity vector

var jump_pressed := false
onready var jump_physics := JumpPhysics.new()

onready var inventory := $Inventory as Inventory

# to fall through a one-way platform, a temporary collision exception is added.
# After OneWayPlatformTimer expires the exception is removed.
var one_way_platform = null


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
		var current_weapon = inventory.lock_current() # prevent current_weapon from changing until we are done
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
		inventory.unlock_current()


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
	var on_floor := is_on_floor()

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
			#var dd = G.get_scene().debug_draw
			#dd.add_vector(knockback, position, INF, 'knock_%s' % config.num)
			if knockback.length() < 100:
				knockback = null
	else:
		# dead
		if on_floor:
			velocity.x = lerp(velocity.x, 0, FRICTION_DECAY)
			velocity.y = jump_physics.FLOOR_VEL # apply a small downwards force to remain on_floor
		else:
			velocity.y += jump_physics.GRAVITY * delta
			velocity.y = clamp(velocity.y, -jump_physics.MAX_SPEED, jump_physics.MAX_SPEED)

	velocity = move_and_slide(velocity, UP)


# get the angle to rotate the weapon by such that the barrel exactly aims at the given position.
# If the barrel isn't along y=0 then a correction term is required.
# pos is relative
func weapon_aim_angle(pos):
	# maths copied from power defence
	var current_weapon = inventory.lock_current()
	var angle = null
	if current_weapon != null:
		var gun_pos = current_weapon.get_position()
		var d = (pos - gun_pos).length()
		if abs(d) > 4: # pixels
			angle = pos.angle_to_point(gun_pos)
			var muzzle_pos = current_weapon.get_node('Muzzle').get_position()
			var o = (muzzle_pos - gun_pos).y
			# cannot accurately aim at something closer than the muzzle
			if d > muzzle_pos.length():
				var angle_correction = asin(o/d)
				if abs(angle+angle_correction) > PI/2:
					angle += angle_correction
				else:
					angle -= angle_correction
	inventory.unlock_current()
	return angle if angle != null else pos.angle()

func set_weapon_angle(angle):
	# _weapon_angle should always be set atomically, ie use a temporary variable
	# and set once at the end otherwise the aiming becomes jittery. This
	# function should deter direct access when writing (reading is OK).
	_weapon_angle = angle


func take_damage(damage: float, knockback: Vector2) -> void:
	if invulnerable or is_dead():
		return
	var old_health := health
	emit_signal('hit')
	_set_health(health - damage)

	if self.knockback == null:
		self.knockback = knockback
	else:
		self.knockback += knockback

	if old_health > 0 and health <= 0:
		die()

# cast a ray of the given length and position (default: current position) which
# can collide with the map and other players. Returns null if no intersection,
# and {'pos':..., 'body':...} if there was.
func cast_ray_down(length: float, pos=null):
	if pos == null:
		var hitbox = $HitBox.shape
		# start the ray a few pixels from the bottom of the hitbox
		pos = global_position + Vector2(0, hitbox.height/2+hitbox.radius-5)
	if length <= 0:
		return null
	var space_state = get_world_2d().direct_space_state
	# from, to, exclude, collision_layer
	var result = space_state.intersect_ray(pos, pos + Vector2(0, length), [self], G.Layers.PLAYERS | G.Layers.MAP)
	if result.empty():
		return null
	else:
		return {'pos': result.position, 'body': result.collider}

# if the player is currently standing on a one way platform: fall through it
func try_fall_through() -> void:
	# shouldn't be non-null because there shouldn't be two one way platforms close enough for this to occur.
	# if this does become a problem then a list of platforms is required instead.
	if one_way_platform == null and is_on_floor():
		var collision = cast_ray_down(40)
		if collision != null:
			var body = collision.body
			if body.has_node('CollisionShape2D') and body.get_node('CollisionShape2D').one_way_collision:
				one_way_platform = body
				add_collision_exception_with(body)
				$OneWayPlatformTimer.start()

func _on_OneWayPlatformTimer_timeout() -> void:
	if one_way_platform != null:
		remove_collision_exception_with(one_way_platform)
		one_way_platform = null

func is_alive() -> bool:
	return health > 0
func is_dead() -> bool:
	return health <= 0
func is_on_screen() -> bool:
	return $Visibility.is_on_screen()

func _set_health(new_health: float) -> void:
	health = max(new_health, 0.0)
	$HealthBar.set_health(float(health)/max_health)

# heal the player without exceeding the maximum health
func heal(amount: float) -> void:
	_set_health(min(health+amount, max_health))

func _set_invulnerable(new_invuln: bool) -> void:
	invulnerable = new_invuln
	if invulnerable:
		($InvulnTimer as Timer).start()
	$HealthBar.set_invulnerable(invulnerable)
	emit_signal('invuln_changed')

func die() -> void:
	if invulnerable:
		return
	_set_health(0)
	collision_layer = 0 # no longer on the players layer
	collision_mask = G.Layers.MAP # only collide with the map, not other players
	$BulletCollider.collision_layer = 0 # no longer collide with projectiles
	emit_signal('die')

#TODO: this should probably be handled in the gameplay code
func spawn(position: Vector2) -> void:
	_set_invulnerable(true)
	self.position = position
	collision_layer = G.Layers.PLAYERS
	collision_mask = G.Layers.PLAYERS | G.Layers.MAP
	$BulletCollider.collision_layer = G.Layers.BULLET_COLLIDERS
	_set_health(max_health)

	inventory.clear()
	inventory.equip(G.pickups['Pistol'].scene.instance())
	inventory.select('Pistol')
	show()

func teleport(location: Vector2) -> void:
	global_position = location
	velocity = Vector2(0, 0)
	move_direction = 0
	knockback = null
	jump_pressed = false
	jump_physics.reset()


func delayed_spawn(position):
	var timer := $SpawnTimer as Timer
	if timer.is_stopped(): # if timer already going, don't restart
		timer.connect('timeout', self, 'spawn', [position], CONNECT_ONESHOT)
		timer.start()

func _on_InvulnTimer_timeout() -> void:
	_set_invulnerable(false)

func _on_weapon_fired(bullets) -> void:
	var current_weapon = inventory.lock_current()
	if current_weapon != null:
		camera.shake(current_weapon.screen_shake)
	inventory.unlock_current()

	if config.control == G.Control.GAMEPAD:
		Input.start_joy_vibration(config.gamepad_id, 0.8, 0.8, 0.5)


func _on_AnimatedSprite_frame_changed() -> void:
	var sprite := $AnimatedSprite as AnimatedSprite
	if sprite.animation == 'run' and (sprite.frame == 1 or sprite.frame == 5):
		($FootstepSound as AudioStreamPlayer2D).play()

