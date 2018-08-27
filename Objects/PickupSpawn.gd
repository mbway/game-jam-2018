extends Area2D

export (NodePath) var available_pickups_path
onready var available_pickups = get_node(available_pickups_path)

var pickup_available = false
var current_pickup = null

#TODO: rather than using the scene tree to specify the pickups, may be able to have a list of weapon scenes as a parameter to the spawn

func _ready():
	random_pickup()

func _process(delta):
	$PickupSprite.position.y = -35 + sin(OS.get_ticks_msec()/800.0) * 8
	$PickupSprite.visible = pickup_available

func set_pickup(i):
	current_pickup = available_pickups.get_child(i)
	$PickupSprite.texture = current_pickup.texture
	var sc = 60.0 / current_pickup.texture.get_size().x # TODO: need a better equation. Doesn't size the revolver well
	$PickupSprite.scale.x = sc
	$PickupSprite.scale.y = sc
	
	pickup_available = true

func random_pickup():
	var i = randi() % available_pickups.get_child_count()
	set_pickup(i)

func _on_Cooldown_timeout():
	random_pickup()


func _on_PickupSpawn_body_entered(body):
	if pickup_available and body.is_in_group('players'):
		body.equip_weapon(current_pickup.scene.instance())
		pickup_available = false
		$Cooldown.start()
