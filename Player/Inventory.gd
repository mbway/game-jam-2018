extends Node2D
class_name Inventory

signal equiped(node)
signal selected(node)
signal unequiped(name)

var current_item = null
# enforced lock order: inventory_lock, current_lock
var inventory_lock := Mutex.new() # protects the child nodes
var current_lock := Mutex.new() # prevents the current item from changing while held

onready var player = get_parent()

# grab a reference to the current weapon and prevent the weapon from changing until the lock is released
func lock_current():
	current_lock.lock()
	return current_item

func unlock_current():
	current_lock.unlock()


func clear():
	inventory_lock.lock()
	current_lock.lock()
	current_item = null
	var names = []
	for w in get_children():
		names.append(w.name)
		w.free() # queue_free here causes crashes
	current_lock.unlock()
	inventory_lock.unlock()
	for n in names:
		emit_signal('unequiped', n)

func equip(item):
	var equipped = null
	inventory_lock.lock()
	if has_node(item.name):
		globals.log_err('player already has inventory item: %s' % item.name)
	else:
		item.setup(player)
		if item.equippable:
			add_child(item)
			equipped = item
	inventory_lock.unlock()
	if equipped != null:
		emit_signal('equiped', equipped)

func select(name):
	if player.is_dead():
		return
	inventory_lock.lock()
	current_lock.lock()
	if current_item != null:
		current_item.set_active(false)
	elif has_node(name):
		#TODO: shouldn't this be if not elif
		current_item = get_node(name)
		current_item.set_active(true)
	else:
		globals.log_err('player does not have inventory item: %s' % name)
	current_lock.unlock()
	inventory_lock.unlock()
	emit_signal('selected', name)

# offset = 1 for next, -1 for prev
func cycle_selection(offset):
	if player.is_dead():
		return
	inventory_lock.lock()
	current_lock.lock()
	var n = get_child_count()
	if current_item != null and n > 0:
		current_item.set_active(false)

		var i = current_item.get_index() + offset
		#TODO: positive modulo?
		if i < 0:
			i += n
		i = i % n

		current_item = get_child(i)
		current_item.set_active(true)
	var selected_name = null if current_item == null else current_item.name
	current_lock.unlock()
	inventory_lock.unlock()
	emit_signal('selected', selected_name)

