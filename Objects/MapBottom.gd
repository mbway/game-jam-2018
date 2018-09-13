extends Node2D

# the Area2D scans for players entering and does the killing, the static body is simply there to stop the player falling any more

func _on_Area2D_body_entered(body):
	if body.is_in_group('players') and body.is_alive():
		body.invulnerable = false # even if invulnerable: die
		body.die()
