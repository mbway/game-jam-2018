tool
extends Node2D

class GraphEdge:
	var a
	var b
	var ab
	var ba
	func _init(array):
		a = array[0]
		b = array[1]
		ab = array[2]
		ba = array[3]

	func to_array():
		return [a, b, ab, ba]


export (PoolVector2Array) var nodes
# can't use a custom class, so instead have to use an array of arrays :(
# each element of edges is an array of [a, b, ab, ba]
export (Array) var edges

# used by the plugin for editing
var edge_start_index = null # index
var moving_index = null
var cursor_pos = null

func _init():
	nodes = PoolVector2Array()
	edges = Array()


func _draw():
	for e in edges:
		draw_edge(GraphEdge.new(e))

	if edge_start_index != null:
		draw_line(nodes[edge_start_index], mouse_pos(), Color('#ffffffff'), 2.0, true)

	if cursor_pos != null:
		draw_circle(cursor_pos, 10.0, Color('#ee000000'))

	for n in nodes:
		draw_circle(n, 7.0, Color('#ff000000'))
		draw_circle(n, 5.0, Color('#ff9999ff'))


func perpendicular_vector(v):
	# dot(u, v) = 0 because perpendicular
	# choose u_x = 1, solve for u_y
	# u_x*v_x + u_y*v_y = 0
	# u_y = -u_x*v_x / v_y
	# then normalise
	if v.y != 0:
		return Vector2(1, -v.x/v.y).normalized()
	else:
		return Vector2(0, 1) # straight up

func draw_edge(edge):
	assert edge.ab or edge.ba
	var a = nodes[edge.a]
	var b = nodes[edge.b]
	var color = Color('#fffd8333')
	draw_line(a, b, color, 2.0, true)

	var v = (b-a).normalized()
	var perp = perpendicular_vector(v)
	var w = 8 # arrow width
	var l = 0.1 * (b-a).length() # arrow length
	# draw arrows
	if edge.ab:
		var x = a + 0.8 * (b-a)
		draw_line(x, x + w*perp - l*v, color, 2.0, true)
		draw_line(x, x - w*perp - l*v, color, 2.0, true)
	if edge.ba:
		var x = a + 0.2 * (b-a)
		draw_line(x, x + w*perp + l*v, color, 2.0, true)
		draw_line(x, x - w*perp + l*v, color, 2.0, true)

func get_edge(index):
	return GraphEdge.new(edges[index])
func set_edge(index, edge):
	edges[index] = edge.to_array()

# returns whether an edge was added
func add_edge(a, b, bidirectional):
	# is a self-loop
	if a == b:
		print('edge is a self loop')
		return false

	for i in range(edges.size()):
		var e = get_edge(i)

		if bidirectional:
			if (e.a == a and e.b == b) or (e.b == a and e.a == b):
				if e.ab and e.ba:
					print('edge already exists')
					return false
				else:
					e.ab = true
					e.ba = true
					set_edge(i, e)
					return true
		else:
			if (e.a == a and e.b == b and e.ab) or (e.b == a and e.a == b and e.ba): # already exists
				print('edge already exists')
				return false
			if e.a == a and e.b == b and not e.ab: # reverse exists
				e.ab = true
				set_edge(i, e)
				return true
			if e.b == a and e.a == b and not e.ba: # reverse exists
				e.ba = true
				set_edge(i, e)
				return true

	# doesn't exist and reverse doesn't exist
	var ba = bidirectional # add the reverse edge if bidirectional
	edges.append([a, b, true, ba])
	return true

func remove_edge(a, b, bidirectional):
	for i in range(edges.size()):
		var e = get_edge(i)
		var ab = bool(e.a == a and e.b == b)
		var ba = bool(e.b == a and e.a == b)

		if ab or ba:
			if bidirectional:
				e.ab = false
				e.ba = false
			elif ab:
				e.ab = false
			elif ba:
				e.ba = false

			if not (e.ab or e.ba):
				edges.remove(i)
			else:
				set_edge(i, e)
			return true
	print('cannot remove edge because it does not exist')
	return false # not found




# so that is_class can be used to determine whether a node is a Graph2D
func is_class(type):
	return type == 'Graph2D' or .is_class(type)
func get_class():
	return 'Graph2D'

# Editing
func mouse_pos():
	return get_local_mouse_position()

func closest_to(pos, max_radius=INF):
	var closest_index = null
	var closest_dist = INF
	for i in range(nodes.size()):
		var d = pos.distance_to(nodes[i])
		if d < closest_dist and d < max_radius:
			closest_index = i
			closest_dist = d
	return closest_index

func closest_to_mouse(max_radius=INF):
	return closest_to(mouse_pos(), max_radius)

func stop_editing():
	edge_start_index = null
	moving_index = null
	cursor_pos = null
	update() # redraw

func add_pending_node():
	nodes.push_back(cursor_pos)
	update() # redraw

func remove_node(index):
	nodes.remove(index)

	# remove any edges involving the node
	var i = 0
	while i < edges.size():
		var e = get_edge(i)
		if e.a == index or e.b == index:
			edges.remove(i)
		else:
			# shift all the indices above the removed node down
			if e.a > index:
				e.a -= 1
			if e.b > index:
				e.b -= 1
			set_edge(i, e)
			i += 1

	update() # redraw

# build an AStar object from the graph
func get_astar():
	var astar = AStar.new()
	for i in range(nodes.size()):
		var n = nodes[i]
		astar.add_point(i, Vector3(n.x, n.y, 0), 1.0) # id, position, weight scale

	for i in range(edges.size()):
		var e = get_edge(i)
		if e.ab and e.ba:
			astar.connect_points(e.a, e.b, true) # bidirectional
		elif e.ab:
			astar.connect_points(e.a, e.b, false)
		elif e.ba:
			astar.connect_points(e.b, e.a, false)

	return astar


