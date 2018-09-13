extends "res://Player/Player.gd"

enum States { EXPLORE, MANUAL }
var state = States.MANUAL

var path_follow

func _ready():
	path_follow = preload('res://Player/AIPathFollow.gd').new(self)

# path following
func _physics_process(delta):
	# handles controlling the player to reach the waypoint by navigating the map
	path_follow.process(delta)

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

