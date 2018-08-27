extends Node2D

onready var G = globals
var red = Color('#ddd95353')  # ARGB
var green = Color('#dd53d953')  # ARGB
var grey = Color('#ddaaaaaa')  # ARGB

func _ready():
	visible = G.settings.get('ai_nodes_visible')

func _process(delta):
	#$MoveTarget.position = get_local_mouse_position()
	$Waypoint.position = get_local_mouse_position()
	update() # redraw. Only calls _draw when visible

func _draw():
	draw_circle($MoveTarget.position, 5, red)
	draw_circle($Waypoint.position, 15, red)

	var left_shape = $LeftCollider/CollisionShape2D.shape
	var left_color = red if is_blocked_left() else grey
	draw_line(left_shape.a, left_shape.b, left_color, 3.0)

	var right_shape = $RightCollider/CollisionShape2D.shape
	var right_color = red if is_blocked_right() else grey
	draw_line(right_shape.a, right_shape.b, right_color, 3.0)

func is_blocked_left():
	var bodies = $LeftCollider.get_overlapping_bodies()
	var count = len(bodies)
	if count > 0 and bodies.has(get_parent()):
		count -= 1
	return bool(count > 0)

func is_blocked_right():
	var bodies = $RightCollider.get_overlapping_bodies()
	var count = len(bodies)
	if count > 0 and bodies.has(get_parent()):
		count -= 1
	return bool(count > 0)
