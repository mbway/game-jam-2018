extends Node2D

export (Texture) var texture
export (int) var heal_amount

const equippable := false

func setup(player):
	player.heal(heal_amount)
