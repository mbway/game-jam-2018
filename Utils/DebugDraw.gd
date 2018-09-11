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

const DEFAULT_COLOR = Color('#ffff0000')
var tmp_counter = 0

var items = {}


class Item:
	# seconds to display for, INF to always display. note: can still be overwritten if another item uses the same name
	var lifetime
	# the name to uniquely identify this item, adding a new item with the same name will replace the old one
	var name
	var color

	func _init(lifetime=INF, name=null, color=DEFAULT_COLOR):
		self.lifetime = lifetime
		self.name = name
		self.color = color

class PointItem:
	extends Item
	var pos
	var radius

	func _init(pos, radius=5, lifetime=INF, name=null, color=DEFAULT_COLOR):
		._init(lifetime, name, color)
		self.pos = pos
		self.radius = radius

	func draw(dd):
		dd.draw_circle(pos, radius, color)

class LineSegmentItem:
	extends Item
	var v1
	var v2

	func _init(v1, v2, lifetime=INF, name=null, color=DEFAULT_COLOR):
		._init(lifetime, name, color)
		self.v1 = v1
		self.v2 = v2

	func draw(dd):
		dd.draw_line(v1, v2, color, true)


class VectorItem:
	extends Item
	var pos
	var vec

	func _init(vec, pos, lifetime=INF, name=null, color=DEFAULT_COLOR):
		._init(lifetime, name, color)
		self.vec = vec
		self.pos = pos

	func draw(dd):
		var end = pos + vec
		dd.draw_line(pos, end, color, true)

		# arrow head
		var perp = dd._perpendicular_vector(vec)
		var n = vec.normalized()
		dd.draw_line(end, end + 5*perp - n*15, color, true)
		dd.draw_line(end, end - 5*perp - n*15, color, true)


# GDscript fails again...
# can't access items from inside one of the inner classes
# https://github.com/godotengine/godot/issues/4472
# so for ease of use, I manually have to create an add_* function for every type :(
# no variadic arguments so I can't even hack something like func add(type, args...)

func add_point(pos, radius=5, lifetime=INF, name=null, color=DEFAULT_COLOR):
	return _add(PointItem.new(pos, radius, lifetime, name, color))
func add_line_segment(v1, v2, lifetime=INF, name=null, color=DEFAULT_COLOR):
	return _add(LineSegmentItem.new(v1, v2, lifetime, name, color))
func add_vector(vec, pos, lifetime=INF, name=null, color=DEFAULT_COLOR):
	return _add(VectorItem.new(vec, pos, lifetime, name, color))

func _add(item):
	if item.name == null:
		item.name = tmp_name()
	items[item.name] = item
	return item.name


func remove(name):
	if not items.has(name):
		print('item "%s" not found' % name)
	else:
		var i = items[name]
		items.erase(name)
		i.free() # not sure if this is necessary...

func _process(delta):
	for k in items.keys():
		var i = items[k]
		i.lifetime -= delta
		if i.lifetime <= 0:
			items.erase(k)
	update()

func _draw():
	for i in items.values():
		i.draw(self)


# Utilities

func tmp_name():
	var name = 'tmp_%s' % tmp_counter
	tmp_counter += 1
	return name

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
