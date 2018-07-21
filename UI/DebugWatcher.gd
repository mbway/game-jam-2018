extends CanvasLayer

var tree
var root
var watches = []

class Watch:
	var node_name
	var node
	var attr
	var tree_item
	
	func _init(watcher, node_name, node, attr):
		self.node_name = node_name
		self.node = node
		self.attr = attr
		
		var parent = watcher.get_subtree(node_name, true)
		self.tree_item = watcher.tree.create_item(parent, -1)
		self.tree_item.set_selectable(0, false)
		self.tree_item.set_text(0, self.attr + ' = ')
		self.tree_item.set_selectable(1, false)
		self.update()
	
	func get_val():
		return self.node.get(self.attr)
	
	func update():
		self.tree_item.set_text(1, str(self.get_val()))


func _ready():
	tree = $Tree
	root = $Tree.create_item()
	

func _process(delta):
	for w in watches:
		w.update()

func add_subtree(name):
	var i = $Tree.create_item(root, -1) # parent, index
	i.set_text(0, name)
	return i
	
func get_subtree(name, create):
	var child = root.get_children() # start at the first child and manually iterate
	while child != null:
		if child.get_text(0) == name:
			return child
		child = child.get_next()
	if create:
		return add_subtree(name)
	else:
		return null

func add_watch(node_name, node, attr):
	var w = Watch.new(self, node_name, node, attr)
	watches.append(w)


