extends Node2D

export (Texture) var texture
export (int) var shoot_vel = 5000
export (int) var damage = 20
export (String) var bullet_scene_path = 'res://Weapons/Bullet.tscn'
export (float) var cooldown = 0.1
export (bool) var auto_fire = false
export (float) var charge = 0
export (float) var spread = 0 # angle of bullet spread in radians
export (float) var screen_shake = 7 # amount of screen shake to add each shot
export (int) var shotCount = 1

# on setup
var is_setup = false
var bullet_scene # the type of bullet to use
var bullet_parent # the node to parent the bullets to
var charge_timer = 0
var fired = false

# runtime
var cooldown_timer = 0
var active = true


func setup(bullet_parent):
	self.bullet_parent = bullet_parent
	bullet_scene = load(bullet_scene_path)
	charge_timer = charge
	set_active(false)

func _process(delta):
	cooldown_timer -= delta

# reutrns whether a shot was fired
func try_shoot(fire_pressed, fire_just_pressed, delta):
	if active and cooldown_timer <= 0 and charge_timer <= 0:
		if (auto_fire and fire_pressed) or fire_just_pressed or (fire_pressed and charge):
			charge_timer = charge
			fired = true
			_shoot()
			return true
	elif charge_timer >= 0 and fire_pressed:
		if charge_timer == charge and has_node('ChargeSound'):
			$ChargeSound.play()
		charge_timer -= delta
	else:
		charge_timer = charge
		fired = false
	return false

func _shoot():
	$FireSound.play()
	if has_node('Flare'):
		$Flare.enabled = true # TODO: disable after timeout
	for i in range(shotCount):
		var bullet = bullet_scene.instance()
		bullet.setup(bullet_parent, self, shoot_vel, damage)
	cooldown_timer = cooldown

func set_active(active):
	self.active = active
	if active:
		show()
	else:
		hide()
