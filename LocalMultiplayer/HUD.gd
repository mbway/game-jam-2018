extends CanvasLayer

func set_score_labels(L, R):
	$P1Score.text = L
	$P2Score.text = R

func show_game_over(winner):
	$GameOver.text = 'Game Over!\n%s Wins' % winner
	$GameOver.show()