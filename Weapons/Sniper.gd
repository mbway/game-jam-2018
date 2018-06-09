extends Node2D

onready var bullet_scene = load('res://Weapons/Bullet.tscn')

export (int) var shoot_vel = 2000

# on setup
var is_setup = false
var bullet_parent
var fire_action

func setup(bullet_parent, fire_action):
	self.bullet_parent = bullet_parent
	self.fire_action = fire_action

func _process(delta):
	$Flare.enabled = false
	if Input.is_action_just_pressed('fire'):
		shoot()

func shoot():
	$Sound.play()
	$Flare.enabled = true
	var bullet = bullet_scene.instance()
	bullet.setup(bullet_parent, self, shoot_vel)
