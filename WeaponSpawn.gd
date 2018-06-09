extends Area2D

onready var pistol_scene = load('res://Weapons/Pistol.tscn')
onready var mg_scene = load('res://Weapons/MachineGun.tscn')
onready var sniper_scene = load('res://Weapons/Sniper.tscn')

onready var playerScene = load('res://Player.tscn')

const COOLDOWN_MAX = 10
var cooldownCount = 5

var ready = true

var WeaponScene = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	if(!ready && cooldownCount <= 0):
		WeaponScene = mg_scene
		#$GunSprite.texture = WeaponScene/Sprite.texture
	
	ready = cooldownCount <= 0
	
	if (!ready):
		cooldownCount -= delta
	
	#if(WeaponScene):
		#if (!ready):
			#$GunSprie.hide()
		#else:
			#$GunSprite.show()


func _on_WeaponSpawn_body_entered(body):
	print((body.get_node()))
	if ready:
		print ('checks out')
		body.equip(WeaponScene)
		cooldownCount = COOLDOWN_MAX
	
