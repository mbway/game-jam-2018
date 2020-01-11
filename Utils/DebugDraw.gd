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

const DEFAULT_COLOR := Color('#ffff0000')
var tmp_counter := 0

var items = {}


class Item:
	# seconds to display for, INF to always display. note: can still be overwritten if another item uses the same name
	var lifetime: float
	# the name to uniquely identify this item, adding a new item with the same name will replace the old one
	var name: String
	var color: Color

	func _init(set_lifetime: float = INF, set_name: String = "", set_color: Color = DEFAULT_COLOR):
		self.lifetime = set_lifetime
		self.name = set_name
		self.color = set_color

class PointItem:
	extends Item
	var pos: Vector2
	var radius: float

	func _init(set_pos: Vector2, set_radius: float = 5.0, set_lifetime: float = INF, set_name: String = "", set_color: Color = DEFAULT_COLOR):
		._init(set_lifetime, set_name, set_color)
		self.pos = set_pos
		self.radius = set_radius

	func draw(dd):
		dd.draw_circle(pos, radius, color)

class LineSegmentItem:
	extends Item
	var v1: Vector2
	var v2: Vector2

	func _init(set_v1: Vector2, set_v2: Vector2, set_lifetime: float = INF, set_name: String = "", set_color: Color=DEFAULT_COLOR):
		._init(set_lifetime, set_name, set_color)
		self.v1 = set_v1
		self.v2 = set_v2

	func draw(dd):
		dd.draw_line(v1, v2, color, true)


class VectorItem:
	extends Item
	var pos: Vector2
	var vec: Vector2

	func _init(set_vec: Vector2, set_pos: Vector2, set_lifetime: float = INF, set_name: String = "", set_color: Color = DEFAULT_COLOR):
		._init(set_lifetime, set_name, set_color)
		self.vec = set_vec
		self.pos = set_pos

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

func add_point(pos: Vector2, radius: float = 5.0, lifetime: float = INF, name: String = "", color: Color = DEFAULT_COLOR) -> String:
	return _add(PointItem.new(pos, radius, lifetime, name, color))
func add_line_segment(v1: Vector2, v2: Vector2, lifetime: float = INF, name: String = "", color: Color = DEFAULT_COLOR) -> String:
	return _add(LineSegmentItem.new(v1, v2, lifetime, name, color))
func add_vector(vec: Vector2, pos: Vector2, lifetime: float = INF, name: String = "", color: Color = DEFAULT_COLOR) -> String:
	return _add(VectorItem.new(vec, pos, lifetime, name, color))

func _add(item) -> String:
	if item.name == "":
		item.name = tmp_name()
	items[item.name] = item
	return item.name


func remove(name: String):
	if not items.has(name):
		print('item "%s" not found' % name)
	else:
		var i = items[name]
		items.erase(name)
		i.free() # not sure if this is necessary...

func _process(delta: float):  # override
	for k in items.keys():
		var i = items[k]
		i.lifetime -= delta
		if i.lifetime <= 0:
			items.erase(k)
	update()

func _draw():  # override
	for i in items.values():
		i.draw(self)


# Utilities

func tmp_name() -> String:
	var name = 'tmp_%s' % tmp_counter
	tmp_counter += 1
	return name

static func _perpendicular_vector(vec: Vector2) -> Vector2:
	return Vector2(vec.y, -vec.x)
