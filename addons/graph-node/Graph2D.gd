tool
extends Node2D
#class_name 'Graph2D' # TODO: uncomment when godot is updated

export (PoolVector2Array) var nodes
# can't use a custom class, so instead have to use an array of arrays :(
# each element of edges is an array of [a, b, ab, ba]
export (Array) var edges

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


# used by the plugin for editing
var edge_start_index = null # index of the start node for the currently editing edge
var moving_index = null # index of the currently moving node
var cursor_pos = null # position of the cursor (black circle). null => hidden

# this AStar instance has node ids which line up with `nodes` and so can be used for either
var _astar = null

func _init():
	nodes = PoolVector2Array()
	edges = Array()

func _ready():
	if not Engine.editor_hint: # in the game
		visible = false
		# can cache because the graph won't change during gameplay
		_astar = _get_astar()

# only called after update() is called, since otherwise the content is static
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

func clear_editing():
	edge_start_index = null
	moving_index = null
	cursor_pos = null
	update() # redraw

func add_pending_node():
	if cursor_pos != null:
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
# note: Astar uses Vector3 nodes
func _get_astar():
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


# the AStar function get_closest_position_in_segment is useless because it
# doesn't return which segment the resulting point lies in, which is required
# for the purposes of subdividing an edge by introducing a point midway through.
# Also the AStar implementation does not give access to the internal edge
# representation at all!, so this has to be implemented using this custom graph
# representation. This function has basically the same implementation but also
# provides the edge index.
func get_closest_edge(p, max_distance=INF):
	# max_distance: ignore any edges that are further than this distance
	var max_distance_sq = max_distance*max_distance # no exponentiation syntax :(
	var closest_edge_index = null
	var closest_p_on_edge = null # point projected onto the segment
	var closest_distance_sq = INF # squared distance between p and the projected p
	for i in range(edges.size()):
		var e = get_edge(i)
		var p_on_edge = Geometry.get_closest_point_to_segment_2d(p, nodes[e.a], nodes[e.b])
		var d_sq = p.distance_squared_to(p_on_edge)
		if d_sq < max_distance_sq and d_sq < closest_distance_sq:
			closest_edge_index = i
			closest_p_on_edge = p_on_edge
			closest_distance_sq = d_sq

	# may be [null, null]
	return [closest_edge_index, closest_p_on_edge]


# project a point to the closest edge, then add that point to the given AStar
# instance, then add edges from the new point to and from the endpoints of the
# closest edge, then return the id of the new point and the id of the closest edge.
func _project_and_add(point, astar):
	var res = get_closest_edge(point)
	var closest_e = res[0] # index of the closest edge to the point
	var projected = res[1] # the point projected onto the closest edge
	if closest_e == null: # problem (probably graph has no edges)
		return [null, null]
	var id = astar.get_available_point_id()
	astar.add_point(id, Vector3(projected.x, projected.y, 0), 1.0)

	var e = get_edge(closest_e)
	#TODO: these have to be unidirectional if the edges are otherwise paths can be wrong
	# there seems to be a bug with AStar which crashes the engine sometimes if
	# these edges are not bidirectional, but this shouldn't be a problem.

	#TODO: there is a bug with godot causing a crash with signal 11 (segfault) when unidirectional edges are added. Check after 3.1 is released and if the bug still persists then look into fixing it.
	#if e.ab and e.ba:
	astar.connect_points(e.a, id, true)
	astar.connect_points(e.b, id, true)
	#elif e.ab:
	#	astar.connect_points(e.a, id, false)
	#	astar.connect_points(id, e.b, false)
	#elif e.ba:
	#	astar.connect_points(e.b, id, false)
	#	astar.connect_points(id, e.a, false)

	return [id, closest_e]

# from and to are 2D vectors
# returns a list of {'pos':..., 'id':...}. The ids of some items may be null because they were only added temporarily
func get_path(from, to):
	var res = _project_and_add(from, _astar)
	var from_id = res[0]
	var from_edge = res[1]
	if from_id == null:
		return []
	assert _astar.has_point(from_id)

	res = _project_and_add(to, _astar)
	var to_id = res[0]
	var to_edge = res[1]
	if to_id == null:
		_astar.remove_point(from_id)
		return []
	assert _astar.has_point(to_id)

	if from_edge == to_edge:
		# this could probably be made into a special case where the path is just
		# [from, to], but just in case there is an edge case, AStar is still used.
		_astar.connect_points(from_id, to_id, true) # bidirectional

	var path = [] # not a pool array because some functions don't exist and the path shouldn't be too long anyway

	var pathIDs = _astar.get_id_path(from_id, to_id)
	for p in pathIDs:
		if p == from_id or p == to_id:
			var v = _astar.get_point_position(p) # Vector3
			path.append({'pos': Vector2(v.x, v.y), 'id': null})
		else:
			path.append({'pos': nodes[p], 'id': p})

	#var path3D = _astar.get_point_path(from_id, to_id)
	#for p in path3D:
		#path.append(Vector2(p.x, p.y))

	_astar.remove_point(from_id)
	_astar.remove_point(to_id)

	return path

# note: returns PoolIntArray
func get_neighbour_ids(node_id):
	if node_id == null:
		return PoolIntArray([])
	else:
		return _astar.get_point_connections(node_id)

