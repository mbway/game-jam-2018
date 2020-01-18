extends Node

const AI_player_scene := preload('res://Player/AI/AIPlayer.tscn')

const NAME = 'Survival'
var G = globals

var is_setup = false
var is_game_over = false
var details
var player_counter = 0
var max_players = 20
var score := 0.0

# nodes
var nodes
var root
var spawn_points
var players
var HUD
var camera

var spawn_timer

func _ready():
	set_process(false)  # the node is present even when not the current mode

func setup(details):
	assert(not is_setup)
	self.details = details
	root = get_node('..')
	nodes = root.get_node('GameMode/Survival')
	spawn_points = nodes.get_node('SpawnPoints')
	players = root.get_node('Players')
	HUD = root.get_node('HUD')
	camera = root.get_node('Camera')


	var p1 = players.get_child(0)
	p1.connect('die', self, '_on_team1_die')
	HUD.connect_player(p1, 1)

	for p in players.get_children():
		assert(p.config.team == 1)
		p.connect('die', self, 'on_player_die', [p])
		if p.config.control != G.Control.AI:
			camera.add_follow(p)
		spawn_player(p, false)
		player_counter = max(player_counter, p.config.num) + 1

	print('setting up spawn timer')
	spawn_timer = Timer.new()
	spawn_timer.set_name('SpawnTimer')
	spawn_timer.set_one_shot(false)
	spawn_timer.set_wait_time(4)
	spawn_timer.connect('timeout', self, '_spawn_zombie')
	spawn_timer.set_autostart(true)
	add_child(spawn_timer)

	HUD.hide_score_labels()
	HUD.show_center_label()

	is_setup = true
	set_process(true)

func _spawn_zombie():
	print('spawning zombie %d' % player_counter)
	var p
	if players.get_child_count() <= max_players:
		var name = 'zombie_%d' % player_counter
		var config = G.PlayerConfig.new(player_counter, name, 2, G.Control.AI)
		player_counter += 1
		p = AI_player_scene.instance()
		p.set_name(name)
		p.init(config, camera, root.get_node('Bullets'), root.get_node('Nav'))
		p.state = AIPlayer.States.FOLLOW
		p.damage_on_contact = true
		players.add_child(p)
	else:
		for player in players.get_children():
			if player.config.control == G.Control.AI and player.is_dead():
				p = player
				break
		if p == null:
			return

	spawn_player(p, false)

func _process(delta: float) -> void:  # override
	if not is_setup:
		return
	if is_game_over:
		HUD.show_game_over('')
	else:
		score += delta
		HUD.set_center_label('Score: %.1f' % score)

func spawn_player(p, delayed):
	if is_game_over:
		return

	var num_spawn_points = spawn_points.get_child_count()
	assert(num_spawn_points > 0)
	var spawn = spawn_points.get_child(randi() % num_spawn_points)
	# spawn offset helps prevent players from spawning directly on top of
	# one another and messing with the physics
	var spawn_offset = Vector2(rand_range(-1,1), rand_range(-1,1))
	if delayed:
		p.delayed_spawn(spawn.position + spawn_offset)
	else:
		p.spawn(spawn.position + spawn_offset)


func _on_team1_die() -> void:
	is_game_over = true

func _on_game_over():
	get_tree().change_scene('res://MainMenu/MainMenu.tscn')
