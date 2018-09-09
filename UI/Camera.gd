extends Camera2D

onready var G = globals

const SHAKE_DECAY = 10 # shake decay per second
const MAX_SHAKE = 200

var follow = [] # nodes to follow
var shake_amount = 0
var shake_enabled = true

# whether the user moves the camera manually with the arrow keys and scroll wheel
var free_camera = false
var free_vel = Vector2(0, 0) # when not following the player, the velocity to move the camera by
const free_speed = 1000
const free_zoom_speed = 0.1
var free_following = true # when in free_camera mode, whether to follow the player


func _ready():
	_on_settings_changed()
	G.settings.connect('settings_changed', self, '_on_settings_changed')

func _process(delta):
	if shake_enabled and shake_amount > 0.1:
		offset.x = rand_range(-1, 1) * shake_amount
		offset.y = rand_range(-1, 1) * shake_amount
		shake_amount -= shake_amount * SHAKE_DECAY * delta
		shake_amount = clamp(shake_amount, 0, MAX_SHAKE)
	else:
		shake_amount = 0
		offset.x = 0
		offset.y = 0


func shake(amount):
	shake_amount = min(shake_amount + amount, MAX_SHAKE)

func _physics_process(delta):
	if free_camera and not free_following:
		global_position += free_vel * delta
		return

	var following = len(follow)

	if following == 1:
		# since only one follower: center the camera directly at it
		set_global_position(follow[0].global_position)

	elif following > 1:
		# center the camera at the mean position of all the nodes being followed
		# set the zoom based on the distance between the furthest two nodes begin followed.

		var avg = Vector2(0,0)
		for f in follow:
			avg += f.global_position
		avg /= len(follow)

		var furthest = Vector2(0,0)
		var furthest_r = 0
		for f in follow:
			var v = f.global_position - avg
			var r = v.length()
			if r > furthest_r:
				furthest = v
				furthest_r = r

		# this is purely heuristic
		furthest.y *= 1.7
		furthest_r = furthest.length()
		var z = max(1, furthest_r / get_viewport().size.x * 3)
		zoom.x = z
		zoom.y = z
		set_global_position(avg)

func _input(event):
	if not free_camera:
		return

	if event is InputEventKey:
		var k = event.scancode

		free_vel = Vector2(0, 0)
		if Input.is_key_pressed(KEY_UP):
			free_vel.y -= free_speed
		if Input.is_key_pressed(KEY_DOWN):
			free_vel.y += free_speed
		if Input.is_key_pressed(KEY_LEFT):
			free_vel.x -= free_speed
		if Input.is_key_pressed(KEY_RIGHT):
			free_vel.x += free_speed

		if event.pressed and not event.is_echo():
			if k == KEY_F:
				free_following = not free_following

	elif event is InputEventMouseButton:
		var b = event.button_index
		if event.pressed:
			if b == BUTTON_WHEEL_UP:
				zoom.x -= free_zoom_speed
				zoom.y -= free_zoom_speed
			elif b == BUTTON_WHEEL_DOWN:
				zoom.x += free_zoom_speed
				zoom.y += free_zoom_speed

func remove_follow(node):
	follow.erase(node)
	update_settings()

func add_follow(node):
	if follow.find(node) == -1:
		follow.append(node)
	update_settings()

func update_settings():
	if len(follow) == 1:
		# prevents jittering
		smoothing_enabled = false
	else:
		smoothing_enabled = true


func _on_settings_changed():
	free_camera = G.settings.get('free_camera')
	shake_enabled = G.settings.get('camera_shake')

