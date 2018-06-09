extends Area2D

const COOLDOWN_MAX = 20
var cooldownCount = 10

var ready = true

var WeaponType = 'pistol'

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	if(!ready && cooldownCount <= 0):
		WeaponType = 'pistol'
	
	ready = cooldownCount <= 0
	
	if (!ready):
		cooldownCount -= delta
		$Gun.hide()
	else:
		$Gun.show()
