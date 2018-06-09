extends Node

onready var pistol_scene = load('res://Weapons/Pistol.tscn')
onready var player_scene = load('res://Player.tscn')

var p1
var p2
var p1_lives = 2
var p2_lives = 2
var game_over = false

func _ready():
	# setup input
	var input = load('res://input.gd').new()
	input.clear_input_maps()
	input.assign_keyboard_mouse_input('p1_')
	input.assign_gamepad_input('p2_')

	p1 = create_player('p1_', 100, true)
	p2 = create_player('p2_', 100, false)

	spawn_player(p1)
	spawn_player(p2)
	$HUD.set_score_labels(p1_lives, p2_lives)


func _on_p1_die():
	p1_lives = max(0, p1_lives - 1)
	$HUD.set_score_labels(p1_lives, p2_lives)
	if p1_lives == 0:
		$HUD.game_over('P2')
	else:
		$P1SpawnTimer.start()


func _on_p2_die():
	p2_lives = max(0, p2_lives - 1)
	$HUD.set_score_labels(p1_lives, p2_lives)
	if p2_lives == 0:
		$HUD.game_over('P1')
	else:
		$P2SpawnTimer.start()

func create_player(prefix, max_health, mouse_look):
	var p = player_scene.instance()
	p.setup(prefix, max_health, $Bullets, $Camera, mouse_look)
	p.equip(pistol_scene.instance())
	p.connect('die', self, '_on_%sdie' % prefix)
	$Players.add_child(p)
	return p

func spawn_player(p):
	if game_over:
		return
	var spawn = $SpawnPoints.get_child(randi() % $SpawnPoints.get_child_count())
	p.spawn(spawn.position)
	$Camera.add_follow(p)

func _on_P1SpawnTimer_timeout():
	spawn_player(p1)

func _on_P2SpawnTimer_timeout():
	spawn_player(p2)
