tool
extends Node

# if importing causes the error: "Nonexistent function 'new' in base 'GDScript'" then
# the actual problem is something with compiling this script: https://github.com/vnen/godot-tiled-importer/issues/73

func post_import(scene):
	for c in scene.get_children():
		if not ['Map', 'Background', 'Collision', 'OneWayCollision'].has(c.name):
			print('Unknown layer: %s' % c.name)
			return null

	# note: collision_layer and collision_mask are both bitmasks

	var collision = scene.get_node('Collision')
	for c in collision.get_children():
		c.collision_layer = 2
		c.collision_mask = 0

	if scene.has_node('OneWayCollision'): # optional
		var one_way_collision = scene.get_node('OneWayCollision')
		for c in one_way_collision.get_children():
			c.collision_layer = 2
			c.collision_mask = 0
			c.get_node('CollisionShape2D').one_way_collision = true

	return scene
