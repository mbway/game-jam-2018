extends CanvasLayer

	
func set_score_labels(p1_lives, p2_lives):
	$P1Score.text = 'P1 Lives: %d' % p1_lives
	$P2Score.text = 'P2 Lives: %d' % p2_lives

func game_over(winner):
	$GameOver.text = 'Game Over!\n%s Wins' % winner
	$GameOver.show()