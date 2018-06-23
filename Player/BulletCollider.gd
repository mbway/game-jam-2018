extends StaticBody2D

# node is in the group 'damageable'

func take_damage(amount):
	get_parent().take_damage(amount)  # the player takes the damage