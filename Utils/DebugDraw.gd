extends Node2D

# a debug drawing utility to quickly draw primitives and have them disappear after some time.
# typical usage would be:
#	var dd = G.get_scene().debug_draw
#	dd.add_vector(...)
# or
#	var name = dd.add_vector(...)
#	after some time
#	dd.remove(name)
# or
#	dd.add_vector(..., 'myvector') # will overwrite every time the name is re-used

enum Types { Vector, Point }
const DEFAULT_COLOR = Color('#ffff0000')
var tmp_counter = 0

var items = {}

func _process(delta):
	for k in items.keys():
		var i = items[k]
		i.lifetime -= delta
		if i.lifetime <= 0:
			items.erase(k)
	update()

# lifetime: seconds to display for, INF to always display. note: can still be overwritten
func add_vector(vec, pos, lifetime=INF, name=null, color=DEFAULT_COLOR):
	name = name if name != null else tmp_name()
	items[name] = {
		'color': color,
		'lifetime': lifetime,
		'pos': pos,
		'type': Types.Vector,
		'vec': vec,
	}
	return name

func add_point(pos, radius=5, lifetime=INF, name=null, color=DEFAULT_COLOR):
	name = name if name != null else tmp_name()
	items[name] = {
		'color': color,
		'lifetime': lifetime,
		'pos': pos,
		'radius': radius,
		'type': Types.Point,
	}
	return name

func tmp_name():
	var name = 'tmp_%s' % tmp_counter
	tmp_counter += 1
	return name

func remove(name):
	if not items.has(name):
		print('item "%s" not found' % name)
	else:
		items.erase(name)

func _draw():
	for i in items.values():
		if i.type == Types.Vector:
			var end = i.pos + i.vec
			draw_line(i.pos, end, i.color, true)

			# arrow head
			var perp = _perpendicular_vector(i.vec)
			var n = i.vec.normalized()
			draw_line(end, end + 5*perp - n*15, i.color, true)
			draw_line(end, end - 5*perp - n*15, i.color, true)
		elif i.type == Types.Point:
			draw_circle(i.pos, i.radius, i.color)



func _perpendicular_vector(v):
	# dot(u, v) = 0 because perpendicular
	# choose u_x = 1, solve for u_y
	# u_x*v_x + u_y*v_y = 0
	# u_y = -u_x*v_x / v_y
	# then normalise
	if v.y != 0:
		return Vector2(1, -v.x/v.y).normalized()
	else:
		return Vector2(0, 1) # straight up
