extends RigidBody2D

## Groups ##
# 'damageable'  (must have a take_damage method)

signal orbDestroyed

var max_health = 100
var health = 0
var active = false

func _ready():
	$SpawnTimer.start()

func spawn():
	health = max_health
	active = true
	$HitBox.disabled = false
	$OrbSprites.play('75')
	show()
	$HoverTimer.start()
	

func take_damage(damage, knockback):
	health -= damage
	
	if !active:
		return
	
	if(health > 75):
		$OrbSprites.play('75')
	elif(health > 60):
		$OrbSprites.play('60')
	elif(health > 45):
		$OrbSprites.play('45')
	elif(health > 30):
		$OrbSprites.play('30')
	elif(health > 15):
		$OrbSprites.play('15')
	elif(health > 0):
		$OrbSprites.play('0')
	else:
		destroyed()

func destroyed():
	hide()
	$DestroySound.play()
	emit_signal('orbDestroyed')
	$SpawnTimer.start()
	active = false
	$HitBox.disabled = true

func move():
	linear_velocity.x = rand_range(-5,5)
	linear_velocity.y = rand_range(-5,5)
	if active:
		$HoverTimer.start()

func _on_SpawnTimer_timeout():
	spawn()


func _on_HoverTimer_timeout():
	move()
