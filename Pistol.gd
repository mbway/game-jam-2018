extends Node2D

onready var bullet_scene = load('res://Bullet.tscn')

export (int) var shoot_vel = 2000

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed('fire'):
		shoot()

func shoot():
	var bullet = bullet_scene.instance()
	bullet.setup(self, shoot_vel)
