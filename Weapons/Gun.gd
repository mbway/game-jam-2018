extends Node2D

export (int) var shoot_vel = 2000
export (String) var bullet_scene_path = 'res://Weapons/Bullet.tscn'
export (float) var cooldown = 0.1
export (bool) var auto_fire = false

# on setup
var is_setup = false
var bullet_scene # the type of bullet to use
var bullet_parent # the node to parent the bullets to
var fire_action # the name of the input mapped action which triggers the gun

# runtime
var cooldown_timer = 0


func setup(bullet_parent, fire_action):
	self.bullet_parent = bullet_parent
	self.fire_action = fire_action
	bullet_scene = load(bullet_scene_path)

func _process(delta):
	cooldown_timer -= delta
	var can_shoot = cooldown_timer <= 0
	if can_shoot:
		if auto_fire and Input.is_action_pressed(fire_action):
				shoot()
		elif Input.is_action_just_pressed(fire_action):
				shoot()
			

func shoot():
	$FireSound.play()
	if has_node('Flare'):
		$Flare.enabled = true # TODO: disable after timeout
	var bullet = bullet_scene.instance()
	bullet.setup(bullet_parent, self, shoot_vel)
	cooldown_timer = cooldown
