extends Node2D

export (int) var max_width = 70

func _ready():
	$Bar.rect_position.x = -max_width/2
	set_health(1.0)
	
func set_health(fraction):
	$Bar.rect_size.x = max(0, fraction * max_width)
	$Label.text = str(int(fraction * 100)) + '%'
	
