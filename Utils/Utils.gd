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

static func listdir(d):
	var files = []
	var dir = Directory.new()
	dir.open(d)
	dir.list_dir_begin()
	while true:
		var f = dir.get_next()
		if f == '':
			break
		if f != '.' and f != '..':
			files.append(f)
	dir.list_dir_end()
	return files
	