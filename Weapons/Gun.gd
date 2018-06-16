extends Node2D

signal fired(bullets)

export (Texture) var texture
export (int) var shoot_vel = 5000
export (int) var damage = 20
export (String) var bullet_scene_path = 'res://Weapons/Bullet.tscn'
export (String) var shell_scene_path = 'res://Weapons/BulletShell.tscn'
export (float) var cooldown = 0.1 # time after firing before the weapon can fire again
export (bool) var auto_fire = false
export (float) var spread = 0 # standard deviation of the angle of bullet spread in radians
export (float) var screen_shake = 7 # amount of screen shake to add each shot
# whether the gun has a charge time after the user pulls the trigger and the gun fires
# weapons with this set to true should contain a ChargeTimer node
# (with timeout connected to _shoot) and a ChargeSound node
export (bool) var requires_charging = false
export (int) var shot_count = 1 # the number of bullets spawned each shot
export (bool) var has_reload_animation = false

# on setup
var is_setup = false
var bullet_scene # the type of bullet to use
var bullet_parent # the node to parent the bullets to
var shell_scene # the type of shell to use
var fired = false

# runtime
var cooldown_timer = null
var can_shoot = true
var active = true


func setup(bullet_parent):
	set_active(false)
	self.bullet_parent = bullet_parent
	bullet_scene = load(bullet_scene_path)
	shell_scene = load(shell_scene_path)

	cooldown_timer = Timer.new()
	cooldown_timer.set_one_shot(true)
	cooldown_timer.set_wait_time(cooldown)
	cooldown_timer.connect('timeout', self, '_on_cooled_down')
	add_child(cooldown_timer)


func try_shoot(fire_held):
	if active and can_shoot: # gun ready
		if not fire_held or (auto_fire and fire_held): # player wants to fire
			# weapons that require charging fire once their timer expires
			if requires_charging and $ChargeTimer.is_stopped():
				can_shoot = false
				$ChargeSound.play()
				$ChargeTimer.start()
			else:
				_shoot()

func _shoot():
	var bullets = []
	for i in range(shot_count):
		var bullet = bullet_scene.instance()
		bullet.setup(bullet_parent, self, shoot_vel, damage)
		bullets.append(bullet)
	
	if has_node('ShellEject'):
		var shell = shell_scene.instance()
		shell.setup(bullet_parent,self)
	
	if has_reload_animation:
		$Sprite.play('reload')
		$Sprite.frame = 0
	
	$FireSound.play()
	can_shoot = false
	cooldown_timer.start()
	emit_signal('fired', bullets)

func set_active(active):
	self.active = active
	self.visible = active # hide when inactive
	# if there is a shot charging when the gun is swapped out: cancel the shot
	if requires_charging and not active:
		$ChargeTimer.stop()
		can_shoot = true


func _on_cooled_down():
	can_shoot = true
