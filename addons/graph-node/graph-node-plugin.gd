tool
extends EditorPlugin

var toolbar
var editing_node = null
enum MODES { AddNodes, MoveNodes, DeleteNodes, AddEdges, DeleteEdges }
var edit_mode = MODES.AddNodes
var mouse_pressed = false # whether the left mouse button is pressed
var last_mouse = null # last mouse position

var selection_radius = 25
var snap_grid_size = 8


func _enter_tree():
	# init plugin
	add_custom_type('Graph2D', 'Node2D', preload('Graph2D.gd'), preload('Assets/icon.png'))

	toolbar = preload('GraphEditToolbar.tscn').instance()
	toolbar.get_node('AddNodes').connect('pressed', self, 'on_add_nodes')
	toolbar.get_node('MoveNodes').connect('pressed', self, 'on_move_nodes')
	toolbar.get_node('DeleteNodes').connect('pressed', self, 'on_delete_nodes')
	toolbar.get_node('AddEdges').connect('pressed', self, 'on_add_edges')
	toolbar.get_node('DeleteEdges').connect('pressed', self, 'on_delete_edges')
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	print('loaded graph plugin')
	make_visible(false)

func _exit_tree():
	# clean up plugin
	remove_custom_type('Graph2D')
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.free()
	print('removed graph plugin')

# when a node is selected in the editor, this gets called. If the function returns true then make_visible and edit are called.
func handles(object):
	return object.is_class('Graph2D')

func make_visible(visible):
	if visible:
		toolbar.show()
		set_process(true)
	else:
		set_process(false)
		toolbar.hide()
		# weakref to detect whether the node has been freed
		if editing_node != null and weakref(editing_node).get_ref() != null:
			editing_node.clear_editing()
			editing_node = null # new node selected

# called when a Graph2D node is selected in the editor
func edit(object):
	assert object.is_class('Graph2D')
	editing_node = object

func on_add_nodes(): # menu button
	edit_mode = MODES.AddNodes
	if editing_node != null:
		editing_node.clear_editing()

func on_move_nodes(): # menu button
	edit_mode = MODES.MoveNodes
	if editing_node != null:
		editing_node.clear_editing()

func on_delete_nodes(): # menu button
	edit_mode = MODES.DeleteNodes
	if editing_node != null:
		editing_node.clear_editing()

func on_add_edges(): # menu button
	edit_mode = MODES.AddEdges
	if editing_node != null:
		editing_node.clear_editing()

func on_delete_edges(): # menu button
	edit_mode = MODES.DeleteEdges
	if editing_node != null:
		editing_node.clear_editing()

func forward_canvas_gui_input(event):
	if editing_node == null:
		return

	if event is InputEventMouseButton:
		var b = event.button_index

		if b == BUTTON_LEFT:
			mouse_pressed = event.pressed

		if event.pressed and b == BUTTON_LEFT:

			if edit_mode == MODES.AddNodes:
				var ur = get_undo_redo()
				ur.create_action('add_node')
				ur.add_do_method(editing_node, 'add_pending_node')
				ur.commit_action()

			elif edit_mode == MODES.MoveNodes:
				var closest_index = editing_node.closest_to_mouse(selection_radius)
				if closest_index != null:
					editing_node.moving_index = closest_index

			elif edit_mode == MODES.DeleteNodes:
				var closest_index = editing_node.closest_to_mouse(selection_radius)
				if closest_index != null:
					var ur = get_undo_redo()
					ur.create_action('remove_node')
					ur.add_do_method(editing_node, 'remove_node', closest_index)
					ur.commit_action()

			elif edit_mode == MODES.AddEdges or edit_mode == MODES.DeleteEdges:
				var closest_index = editing_node.closest_to_mouse(selection_radius)
				if closest_index != null:
					if editing_node.edge_start_index == null:
						editing_node.edge_start_index = closest_index
					else:
						var bidirectional = toolbar.get_node('Bidirectional').is_pressed()
						var ur = get_undo_redo()
						if edit_mode == MODES.AddEdges:
							ur.create_action('add_edge')
							ur.add_do_method(editing_node, 'add_edge', editing_node.edge_start_index, closest_index, bidirectional)
						elif edit_mode == MODES.DeleteEdges:
							ur.create_action('delete_edge')
							ur.add_do_method(editing_node, 'remove_edge', editing_node.edge_start_index, closest_index, bidirectional)

						ur.commit_action()

						editing_node.edge_start_index = null
						editing_node.update()
			return true # handled

		if not event.pressed and b == BUTTON_LEFT:
			if edit_mode == MODES.MoveNodes:
				if editing_node.moving_index != null:
					var ur = get_undo_redo()
					ur.create_action('move_node')
					ur.commit_action()
					editing_node.clear_editing() # once released, have to re-select a node to move it
			return true # handled

	return false # not handled

func snap_to(v, step):
	return round(v/step) * step

func snapped_mouse_pos():
	var mouse = editing_node.mouse_pos()
	mouse.x = snap_to(mouse.x, snap_grid_size)
	mouse.y = snap_to(mouse.y, snap_grid_size)
	return mouse


func _process(delta):
	# Engine.editor_hint doesn't work here because I think that it still returns
	# true because the plugin is running in the editor even when the game is
	# active.

	if editing_node == null:
		return

	# this value changes even if the cursor remains still but the camera zooms
	var m = editing_node.mouse_pos()
	if last_mouse != m:
		on_mouse_moved()
		last_mouse = m


func on_mouse_moved():
	# can't just update when the mouse moves because the camera can change without the mouse moving
	if edit_mode == MODES.AddNodes:
		editing_node.cursor_pos = snapped_mouse_pos()
		editing_node.update()

	elif edit_mode == MODES.MoveNodes:
		if mouse_pressed and editing_node.moving_index != null:
			var mouse = snapped_mouse_pos()
			editing_node.nodes[editing_node.moving_index] = mouse
			editing_node.cursor_pos = mouse
		else:
			var closest_index = editing_node.closest_to_mouse(selection_radius)
			editing_node.cursor_pos = null if closest_index == null else editing_node.nodes[closest_index]
		editing_node.update()

	elif [MODES.DeleteNodes, MODES.AddEdges, MODES.DeleteEdges].has(edit_mode):
		var closest_index = editing_node.closest_to_mouse(selection_radius)
		editing_node.cursor_pos = null if closest_index == null else editing_node.nodes[closest_index]
		editing_node.update()



