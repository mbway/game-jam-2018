extends Node2D

const font = preload('res://Assets/fonts/source_code_pro/source_code_pro_regular_16.tres')

onready var G = globals
# ARGB colors
const red := Color('#ddd95353')
const green := Color('#dd53d953')
const blue := Color('#dd5353d9')
const grey := Color('#ddaaaaaa')
const pink := Color('#ddef1b91')
const purple := Color('#dd791bef')
const light_grey := Color('#55aaaaaa')


var falls_short := false
var fall_short_pos = null

onready var player = get_parent()

func _ready():
	visible = G.settings.get('ai_nodes_visible')

func _process(delta):
	#$MoveTarget.position = get_local_mouse_position()
	#$Waypoint.position = get_local_mouse_position()
	update() # redraw. Only calls _draw when visible

func _draw():
	var t = player.path_follow.get_target_relative()
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

	draw_rect(get_collision_rect($SearchArea/CollisionShape2D), light_grey, true) # filled

	var path = []
	for p in player.path_follow.path: # the navigation path being followed
		path.append(p.pos)

	for i in range(path.size()):
		var pos := to_local(path[i])
		draw_circle(pos, 4, blue)
		draw_string(font, pos, String(i))
	path = [player.position, player.position+t] + path
	for i in range(1, len(path)):
		draw_line(to_local(path[i-1]), to_local(path[i]), blue, 2, true)

func draw_collider(collider):
	var shape = collider.get_node('CollisionShape2D').shape
	var color = red if is_colliding(collider) else grey
	draw_line(shape.a, shape.b, color, 3.0)

func get_collision_rect(r):
	var pos = r.position
	var e = r.shape.extents # shape.extents are actually half extents
	return Rect2(pos.x-e.x, pos.y-e.y, e.x*2, e.y*2)

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
