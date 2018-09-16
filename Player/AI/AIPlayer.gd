extends "res://Player/Player.gd"

enum States { EXPLORE, MANUAL }
var state = States.MANUAL

var known_players = []
var target = null

var path_follow

func _ready():
	path_follow = preload('res://Player/AI/PathFollow.gd').new(self)

# path following
func _physics_process(delta):
	# handles controlling the player to reach the waypoint by navigating the map
	path_follow.process(delta)

func _process(delta):
	if is_dead():
		return

	if target == null and not known_players.empty():
		target = known_players[0]

	if target != null:
		set_weapon_angle(weapon_aim_angle(to_local(target.global_position)))
		#current_weapon.try_shoot(false)



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
