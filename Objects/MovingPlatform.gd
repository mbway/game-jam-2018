extends Node2D

export (PackedScene) var Platform = preload('res://Objects/GrassPlatform.tmx')
export (Vector2) var move_to = Vector2(0, 0)
export (float) var period = 2 # seconds to travel to move_to and back

var platform
var timer = 0

# TODO: add tool functionality to preview the path that the platform takes in the editor

# TODO: get a reference to the navigation graph, find any nodes which are above this platform and make a note of them and their offset relative to this node.
#  when moving, move the nodes and remove edges which get too long and add them back in once back in range. Then again this might not be the best idea
#  because the AI doesn't expect parts of the path to dissapear while traversing. perhaps the AI could have a special case to not move the target on if the target is
#  above a movable platform and the node is far away?

func _ready():
	platform = Platform.instance()
	add_child(platform)

func _physics_process(delta):
	var progress = 0.5 + 0.5*sin(PI*timer/period)
	platform.position = move_to * progress
	timer += delta