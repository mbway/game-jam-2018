class TrackedValue:
	var last_val = null
	var val = null

	func _init(initial_value):
		reset(initial_value)

	func changed():
		return val != last_val

	func set(new_val):
		last_val = val
		val = new_val

	func reset(value): # set both values
		last_val = value
		val = value
