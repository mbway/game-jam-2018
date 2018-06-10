extends Sprite

func _process(delta):
	region_rect.position.x += delta * 1500
	region_rect.position.y -= delta * 50