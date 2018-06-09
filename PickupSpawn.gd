extends Area2D

onready var pistol_scene = load('res://Weapons/Pistol.tscn')
onready var mg_scene = load('res://Weapons/MachineGun.tscn')
onready var sniper_scene = load('res://Weapons/Sniper.tscn')

onready var player_scene_path = 'res://Player.tscn'

var pickup_available = false
var pickup_scene = null


func _ready():
	set_pickup(sniper_scene)
	
func _process(delta):
	pass
	#$GunSprite.texture = WeaponScene/Sprite.texture


func set_pickup(p):
	pickup_scene = p
	pickup_available = true

func _on_Cooldown_timeout():
	set_pickup(mg_scene)


func _on_PickupSpawn_body_entered(body):
	if pickup_available and body.get_filename() == player_scene_path:
		print('giving weapon')
		print(pickup_scene)
		body.equip(pickup_scene.instance())
		$Cooldown.start()
