extends "res://Player/Player.gd"

var Math = preload('res://Utils/Math.gd')

enum States { EXPLORE, MANUAL }
var state = States.EXPLORE

var known_players = [] # players within the search area
var target = null # the player being attacked

var timer = 0 # the game time

# exploration
var last_visited = [] # timer values for when the player last visited each node in nav
const EXPLORE_PATH_LEN = 5 # keep the exploration path at this length

onready var path_follow = preload('res://Player/AI/PathFollow.gd').new(self)

func _ready():
	for n in nav.nodes:
		last_visited.append(0)

# path following
func _physics_process(delta):
	# handles controlling the player to reach the waypoint by navigating the map
	path_follow.process(delta)

	timer += delta

# called by path_follow when the target is set (and the previous target is passed)
func _on_passed_through(node):
	if node != null and node.id != null:
		last_visited[node.id] = timer

func _process(delta):
	if is_dead():
		return

	# handle combat
	if target == null:
		# find a target
		if not known_players.empty():
			target = known_players[0]
	else:
		# attack the target
		set_weapon_angle(weapon_aim_angle(to_local(target.global_position)))
		#current_weapon.try_shoot(false)

	# handle exploration
	if state == States.EXPLORE:
		while path_follow.path.size() < EXPLORE_PATH_LEN:
			if path_follow.path.empty():
				# have to start a path
				# get the closest nodes to the left and right on the same platform as the player
				var platform_nodes = path_follow.get_nearest_platform_nodes(position)
				if platform_nodes == null:
					break # not on a platform yet
				else:
					# left or right ids may be null (but not both) if there are no nodes in that direction
					platform_nodes.erase(null)
					path_follow.path_append(Math.random_choice(platform_nodes))
			else:
				# extend the path
				var path_len = path_follow.path.size()
				var path_end = path_follow.path[path_len-1]
				var neigbour_ids = nav.get_neighbour_ids(path_end.id)
				if neigbour_ids.size() == 0:
					break # can't add any more to the path
				elif path_len > 1:
					var path_penultimate = path_follow.path[path_len-2]
					# create an unnormalized distribution which discourages backtracking (but doesn't disallow it)
					var distribution = []
					for n in neigbour_ids:
						if n == path_penultimate.id:
							distribution.append(1)
						else:
							distribution.append(5)
					var n = Math.random_choice(neigbour_ids, distribution, false)
					path_follow.path_append(n) # normalized
				else:
					#TODO: may want to avoid having the player move in one direction then immediately turn around because at this point either direction is equally good at the moment
					path_follow.path_append(Math.random_choice(neigbour_ids))



func set_state(s):
	path_follow.clear_path()
	state = s



# can't use _unhandled_input otherwise won't receive mouse events when over a Control node
func _input(event):
	if is_alive() and state == States.MANUAL:
		if event is InputEventMouseButton:
			var b = event.button_index
			if event.pressed:
				if b == BUTTON_LEFT:
					var mouse = get_global_mouse_position()
					print('tp %s %s,%s; player_set %s waypoint %s,%s;;' % [config.num, global_position.x, global_position.y, config.num, mouse.x, mouse.y])
					path_follow.set_waypoint(mouse)


func _on_player_enter_SearchArea(player):
	if player == self or not player.is_in_group('players'):
		return
	known_players.append(player)
	print('enter ', player)


func _on_player_exit_SearchArea(player):
	known_players.erase(player)
	if player == target:
		target = null
	print('exit ', player)
