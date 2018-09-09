extends Area2D

var G = globals

onready var pickup_names = G.pickups.keys()

var current_pickup = null # a dictionary with scene and texture keys
var t = 0 # game time


func _ready():
	pickup_names.erase('pistol') # don't want to spawn this
	set_pickup(random_pickup_name())

func _process(delta):
	if current_pickup != null:
		$PickupSprite.position.y = -35 + sin(t/0.8) * 8
		t += delta

func set_pickup(name):
	current_pickup = G.pickups[name]
	var sprite = $PickupSprite
	sprite.texture = current_pickup.texture
	var sc = 60.0 / current_pickup.texture.get_size().x # TODO: need a better equation. Doesn't size the revolver well
	sprite.scale.x = sc
	sprite.scale.y = sc
	sprite.visible = true

func random_pickup_name():
	var i = randi() % pickup_names.size()
	return pickup_names[i]

func _on_Cooldown_timeout():
	set_pickup(random_pickup_name())

func give_pickup_to(player):
	player.equip_weapon(current_pickup.scene.instance())
	current_pickup = null
	$PickupSprite.visible = false
	$Cooldown.start()

func _on_PickupSpawn_body_entered(body):
	if current_pickup != null and body.is_in_group('players'):
		give_pickup_to(body)