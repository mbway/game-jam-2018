extends Node2D

export (int) var max_width = 70

func _ready():
	$Bar.rect_position.x = -max_width/2
	set_health(1.0)

func set_invulnerable(invuln):
	if invuln:
		$Bar.self_modulate = Color('#ff000000')
	else:
		$Bar.self_modulate = Color('#ffffffff')

func set_health(fraction):
	$Bar.rect_size.x = clamp(fraction, 0, 1) * max_width
	if fraction <= 0:
		$Label.text = ''
	else:
		$Label.text = str(int(fraction * 100)) + '%'
	
