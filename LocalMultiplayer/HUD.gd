extends CanvasLayer

func _ready():
	$Message.hide()
	$GameOver.hide()
	
func set_score_labels(L, R):
	$P1Score.text = L
	$P2Score.text = R

func show_game_over(winner):
	$GameOver.text = 'Game Over!\n%s Wins' % winner
	$GameOver.show()

func show_message(text):
	$Message.text = text
	$Message.show()
	$Message/Timeout.start()

func _on_Timeout_timeout():
	$Message.hide()
