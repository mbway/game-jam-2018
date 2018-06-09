extends Area2D

const player_scene_path = 'res://Player.tscn'

export (NodePath) var available_pickups_path
onready var available_pickups = get_node(available_pickups_path)

var pickup_available = false
var current_pickup = null


func _ready():
	set_pickup(0)
	
func _process(delta):
	pass


func set_pickup(i):
	current_pickup = available_pickups.get_child(i)
	$PickupSprite.texture = current_pickup.texture
	print($PickupSprite.texture)
	pickup_available = true

func _on_Cooldown_timeout():
	set_pickup(0)


func _on_PickupSpawn_body_entered(body):
	if pickup_available and body.get_filename() == player_scene_path:
		print('giving', current_pickup.name)
		body.equip(current_pickup.scene.instance())
		$Cooldown.start()
