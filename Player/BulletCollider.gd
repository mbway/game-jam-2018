extends StaticBody2D

# node is in the group 'damageable'

func take_damage(amount: float, knockback: Vector2):
	get_parent().take_damage(amount, knockback)  # the player takes the damage
