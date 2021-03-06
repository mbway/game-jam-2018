tool
extends Node

# if importing causes the error: "Nonexistent function 'new' in base 'GDScript'" then
# the actual problem is something with compiling this script: https://github.com/vnen/godot-tiled-importer/issues/73

func post_import(scene):
	for c in scene.get_children():
		if not ['Map', 'Foreground', 'Background', 'Collision', 'OneWayCollision'].has(c.name):
			printerr('Tiled Post Import: Unknown layer: %s' % c.name)
			return null

	# note: collision_layer and collision_mask are both bitmasks

	var map = scene.get_node('Map')
	_fix_tile_offset(map)

	var foreground = scene.get_node_or_null('Foreground')
	if foreground != null:
		_fix_tile_offset(foreground)
		foreground.z_index = 2

	var background = scene.get_node_or_null('Background')
	if background != null:
		_fix_tile_offset(background)
		background.z_index = -2

	var collision = scene.get_node('Collision')
	for c in collision.get_children():
		_init_collision(c)

	var one_way_collision = scene.get_node_or_null('OneWayCollision')
	if one_way_collision != null:
		for c in one_way_collision.get_children():
			_init_collision(c)
			c.get_node('CollisionShape2D').one_way_collision = true

	return scene

static func _init_collision(c):
	c.collision_layer = 2
	c.collision_mask = 0
	var shape = c.get_child(0).shape
	if shape.extents.x <= 0 or shape.extents.y <= 0:
		printerr('Tiled Post Import: collision shapes must have non-zero area (so they are visible in the editor)')
		assert(false)

static func _fix_tile_offset(node):
	# required due to the following bug. Remove once fixed upstream
	# https://github.com/vnen/godot-tiled-importer/issues/114
	node.position.y += 32
