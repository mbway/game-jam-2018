extends Node2D

signal fired(bullets)

export (float) var shoot_speed := 5000.0
export (float) var damage := 20.0
export (PackedScene) var bullet_scene = preload('res://Weapons/Projectiles/Bullet.tscn')
export (PackedScene) var shell_scene = preload('res://Weapons/BulletShell.tscn')
export (float) var cooldown := 0.1 # time after firing before the weapon can fire again
export (bool) var auto_fire := false
export (int) var bullets_per_shot := 1
export (bool) var has_reload_animation := false  #TODO: can determine this without setting a flag

export (Texture) var texture  # (used by PickupSpawn)
export (float) var spread = 0.0 # (used by Bullet) standard deviation of the angle of bullet spread in radians
export (float) var screen_shake = 7.0 # (used by Player) amount of screen shake to add each shot

# used by Inventory
const equippable := true

# on setup
var bullet_parent = null # the node to parent the bullets to
var player = null # the player holding the gun

# runtime
var cooldown_timer := Timer.new()
var can_shoot := true
var active := true


func setup(set_player):
	assert(player == null)
	set_active(false)
	player = set_player
	bullet_parent = player.bullet_parent
	connect('fired', player, '_on_weapon_fired')

	cooldown_timer.set_one_shot(true)
	cooldown_timer.set_wait_time(cooldown)
	cooldown_timer.connect('timeout', self, '_on_cooled_down')
	add_child(cooldown_timer)


func try_shoot(fire_held: bool):
	if active and can_shoot: # gun ready
		if not fire_held or (auto_fire and fire_held): # player wants to fire
			# weapons that require charging fire once their timer expires
			if _requires_charging() and $ChargeTimer.is_stopped():
				can_shoot = false
				$ChargeSound.play()
				$ChargeTimer.start()
			else:
				_shoot()

func _shoot():
	var bullets = []
	for _i in range(bullets_per_shot):
		var bullet = bullet_scene.instance()
		bullet.setup(player, bullet_parent, self, shoot_speed, damage)
		bullets.append(bullet)

	if has_node('ShellEject'):
		var shell = shell_scene.instance()
		shell.setup(bullet_parent, self)

	if has_reload_animation:
		$Sprite.frame = 0
		$Sprite.play('reload')

	$FireSound.play()
	can_shoot = false
	cooldown_timer.start()
	emit_signal('fired', bullets)

func set_active(new_active: bool):
	active = new_active
	visible = new_active # hide when inactive
	if _requires_charging() and not new_active:
		$ChargeTimer.stop()
		can_shoot = true

func _on_cooled_down():
	can_shoot = true

func _requires_charging() -> bool:
	# whether the gun has a charge time after the user pulls the trigger and the gun fires
	# - The ChargeTimer node should have timeout connected to _shoot
	# - the gun should also have a ChargeSound node
	return has_node("ChargeTimer")
