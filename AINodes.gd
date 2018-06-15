extends Node2D

var globals
var red = Color('#ccd95353')  # ARGB
var grey = Color('#cccdcdcd')  # ARGB

func _ready():
	globals = get_node('/root/globals')
	visible = globals.DEBUG

func _process(delta):
	$MoveTarget.position = get_local_mouse_position()
	update() # redraw. Only calls _draw when visible

func _draw():
	draw_circle($MoveTarget.position, 5, red)

	var left_shape = $LeftCollider/CollisionShape2D.shape
	var left_color = red if is_blocked_left() else grey
	draw_line(left_shape.a, left_shape.b, left_color, 3.0)

	var right_shape = $RightCollider/CollisionShape2D.shape
	var right_color = red if is_blocked_right() else grey
	draw_line(right_shape.a, right_shape.b, right_color, 3.0)

func is_blocked_left():
	return len($LeftCollider.get_overlapping_bodies()) > 0
func is_blocked_right():
	return len($RightCollider.get_overlapping_bodies()) > 0
