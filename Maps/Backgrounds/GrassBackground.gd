extends Node2D

var clouds

func _ready():
	clouds = find_node("Clouds")
	for layer in $ParallaxBackground.get_children():
		layer.visible = true

func _process(delta):
	clouds.region_rect.position.x += delta * 20
