tool
extends Node

func post_import(scene):
	var collision = scene.get_node('Collision')
	for c in collision.get_children():
		# both are bit masks
		c.collision_layer = 2
		c.collision_mask = 0
	
	return scene