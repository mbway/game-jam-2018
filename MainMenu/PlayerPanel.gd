extends Control

signal delete

var player_sprite

func set_player_color(color: Color):
	$ColorPicker.set_pick_color(color)
	player_sprite.set_modulate(color)

func get_player_details():
	return {
		"name": find_node("PlayerName").text,
		"team": find_node("TeamOption").selected,
		"input_method": find_node('ControlOption').selected,  # value not index
		"color": player_sprite.get_modulate()
	}

func setup(name, teams, input_methods, default_team, default_input_method):
	find_node("PlayerName").text = name

	var controls = find_node('ControlOption')
	for i in input_methods:
		controls.add_item(i['name'])
	controls.select(default_input_method)

	var team = find_node('TeamOption')
	for t in teams:
		team.add_item(t)
	team.select(default_team)

func _ready():
	player_sprite = find_node("PlayerSprite", true)

func _on_color_changed(color):
	player_sprite.set_modulate(color)

func _on_ColorPickerButton_pressed():
	$ColorPicker.visible = !$ColorPicker.visible

func _on_DeleteButton_pressed():
	emit_signal("delete")
