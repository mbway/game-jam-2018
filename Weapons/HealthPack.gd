extends Node2D

export (Texture) var texture
export (int) var heal_amount

var equippable = false

func setup(player):
	player.heal(heal_amount)
