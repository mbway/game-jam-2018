class_name Utils

static func list_dir(path: String) -> Array:
	var files := []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == '':
			break
		if f != '.' and f != '..':
			files.append(f)
	dir.list_dir_end()
	return files
