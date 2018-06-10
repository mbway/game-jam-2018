extends Node

onready var player_scene = load('res://Player.tscn')

var p1
var p2
var p1_lives = 2
var p2_lives = 2
var game_over = false

func _ready():
	randomize() # generate true random numbers
	
	# setup input
	var input = load('res://input.gd').new()
	input.clear_input_maps()
	input.assign_keyboard_mouse_input('p1_')
	input.assign_gamepad_input('p2_')
	input.list_maps('p2_fire')
	input.list_maps('p2_abc')

	p1 = create_player('p1_', 100, true, 1)
	p1.connect('weapon_equiped', $HUD/P1WeaponSlots, '_on_Player_weapon_equiped')
	p1.connect('weapon_selected', $HUD/P1WeaponSlots, '_on_Player_weapon_selected')
	p2 = create_player('p2_', 100, false, 2)
	p2.connect('weapon_equiped', $HUD/P2WeaponSlots, '_on_Player_weapon_equiped')
	p2.connect('weapon_selected', $HUD/P2WeaponSlots, '_on_Player_weapon_selected')
	

	spawn_player(p1)
	spawn_player(p2)
	update_HUD()

func update_HUD():
	$HUD.set_score_labels('P1: %d' % p1_lives, 'P2: %d' % p2_lives)
	

func _on_p1_die():
	p1_lives = max(0, p1_lives - 1)
	update_HUD()
	if p1_lives == 0:
		$HUD.show_game_over('P2')
	else:
		$P1SpawnTimer.start()


func _on_p2_die():
	p2_lives = max(0, p2_lives - 1)
	update_HUD()
	if p2_lives == 0:
		$HUD.show_game_over('P1')
	else:
		$P2SpawnTimer.start()

func create_player(prefix, max_health, mouse_look, team):
	var p = player_scene.instance()
	p.setup(prefix, max_health, $Bullets, $Camera, mouse_look, team)
	p.connect('die', self, '_on_%sdie' % prefix)
	$Players.add_child(p)
	return p

func spawn_player(p):
	if game_over:
		return
	var spawn = $SpawnPoints.get_child(randi() % $SpawnPoints.get_child_count())
	# spawn offset helps prevent players from spawning directly on top of
	# one another and messing with the physics
	var spawn_offset = Vector2(rand_range(-1,1), rand_range(-1,1))
	p.spawn(spawn.position + spawn_offset)
	$Camera.add_follow(p)

func _on_P1SpawnTimer_timeout():
	spawn_player(p1)

func _on_P2SpawnTimer_timeout():
	spawn_player(p2)
