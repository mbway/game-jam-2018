extends Node2D

onready var G = globals
# ARGB colors
var red = Color('#ddd95353')
var green = Color('#dd53d953')
var blue = Color('#dd5353d9')
var grey = Color('#ddaaaaaa')
var pink = Color('#ddef1b91')
var purple = Color('#dd791bef')

var falls_short = false
var fall_short_pos = null

onready var player = get_parent()

func _ready():
	visible = G.settings.get('ai_nodes_visible')

func _process(delta):
	#$MoveTarget.position = get_local_mouse_position()
	#$Waypoint.position = get_local_mouse_position()
	update() # redraw. Only calls _draw when visible

func _draw():
	var t = player.get_target_relative()
	draw_circle(t, 5, red)
	
	if fall_short_pos != null:
		var v = to_local(fall_short_pos)
		var c = pink if falls_short else purple
		draw_line(Vector2(0, 0), v, c, 1.5, true)
		draw_circle(v, 8, c)
	
	draw_collider($LeftCollider)
	draw_collider($RightCollider)
	draw_collider($LeftEdgeDetector)
	draw_collider($RightEdgeDetector)

	var path = player.path # the navigation path being followed
	for p in path:
		draw_circle(to_local(p), 4, blue)
	path = [player.position, player.position+t] + path
	for i in range(1, len(path)):
		draw_line(to_local(path[i-1]), to_local(path[i]), blue, 2, true)
	
func draw_collider(collider):
	var shape = collider.get_node('CollisionShape2D').shape
	var color = red if is_colliding(collider) else grey
	draw_line(shape.a, shape.b, color, 3.0)
	
func is_colliding(collider):
	var bodies = collider.get_overlapping_bodies()
	var count = len(bodies)
	# Area2D doesn't implement collision exceptions
	if count > 0 and bodies.has(player):
		count -= 1
	return bool(count > 0)


func is_obstructed(direction):
	if direction < 0:
		return is_colliding($LeftCollider)
	elif direction > 0:
		return is_colliding($RightCollider)
	else:
		return false

func is_about_to_fall(direction):
	if direction < 0:
		return not is_colliding($LeftEdgeDetector)
	elif direction > 0:
		return not is_colliding($RightEdgeDetector)
	else:
		return false
