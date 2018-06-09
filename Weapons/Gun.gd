extends Node2D

export (int) var shoot_vel = 3000
export (int) var damage = 20
export (String) var bullet_scene_path = 'res://Weapons/Bullet.tscn'
export (float) var cooldown = 0.1
export (bool) var auto_fire = false
export (float) var charge = 0
export (float) var spread = 0 #angle of bullet spread in radians 

# on setup
var is_setup = false
var bullet_scene # the type of bullet to use
var bullet_parent # the node to parent the bullets to
var charge_time = 0

# runtime
var cooldown_timer = 0
var active = true


func setup(bullet_parent):
	self.bullet_parent = bullet_parent
	bullet_scene = load(bullet_scene_path)
	charge_time = charge

func _process(delta):
	cooldown_timer -= delta

func try_shoot(fire_pressed, fire_just_pressed):
	if active and cooldown_timer <= 0:
		if (auto_fire and fire_pressed) or fire_just_pressed:
			_shoot()

func _shoot():
	$FireSound.play()
	if has_node('Flare'):
		$Flare.enabled = true # TODO: disable after timeout
	var bullet = bullet_scene.instance()
	bullet.setup(bullet_parent, self, shoot_vel, damage)
	cooldown_timer = cooldown

func set_active(active):
	self.active = active
	if active:
		show()
	else:
		hide()
