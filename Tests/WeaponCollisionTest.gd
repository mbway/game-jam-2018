extends Node2D

var G = globals

var hit = false
var test_finished = true
var test_distance = 20
var test_distance_max = 1000
var test_distance_delta = 1
var test_width = 1
var test_angle = -PI / 4
var bullet

func _ready():
	var config = G.PlayerConfig.new()
	$Player.init(config, null, $Bullets, null)
	$Player.spawn(Vector2(0, 0))
	
	var current_weapon = $Player.inventory.lock_current()
	current_weapon.connect("fired", self, "_on_weapon_fired")
	$Player.inventory.unlock_current()

func _process(delta):
	if test_finished and test_distance < test_distance_max:
		test_distance += test_distance_delta
		run_test()
	
	if bullet != null and bullet.position.x > test_distance_max:
		_on_miss()

func run_test():
	test_finished = false
	$Collider.position.x = test_distance
	$Collider/CollisionShape2D.shape.extents.x = test_width
	var current_weapon = $Player.inventory.lock_current()
	$Player.set_weapon_angle(test_angle)
	current_weapon._shoot()
	$Player.inventory.unlock_current()

func _on_weapon_fired(bullets):
	assert(bullets.size() == 1)
	bullet = bullets[0]
	bullet.connect("body_entered", self, "_on_hit")

func _on_hit(body):
	hit = true
	test_finished = true
	bullet.queue_free()
	bullet = null
	# printerr('test passed: ', test_distance, ", ", test_width)

func _on_miss():
	hit = false
	test_finished = true
	bullet.queue_free()
	bullet = null
	printerr('test failed: ', test_distance, ", ", test_width)
