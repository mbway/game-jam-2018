
var G = globals
var Math = preload('res://Utils/Math.gd')
var player

# start_diff is calculated by multiplying by the subtended angle by a factor between 1 and this value.
# larger => the auto aim influences a larger angle range
var max_start_diff_multiply = 4
var start_influence = 0.1 # the influence when the angle difference is equal to start_diff
var max_influence = 0.8 # the influence when the angle difference is 0
var power = 2 # has to be even and >0. 2 => Gaussian, >2 => super Gaussian. Larger => influence changes more harshly

func _init(player):
	self.player = player

func auto_aim(raw_angle):
	var min_angle_diff = INF
	var closest_player = null
	for p in G.get_scene().get_players():
		if p != player and p.is_alive() and p.is_on_screen():
			var diff = abs(Math.shortest_angle_between(raw_angle, (p.position-player.position).angle()))
			if diff < min_angle_diff:
				min_angle_diff = diff
				closest_player = p

	if closest_player != null:
		return auto_aim_at(raw_angle, closest_player)
	else:
		return raw_angle

func auto_aim_at(raw_angle, target_player):
	# the weapon-dependent aim angle is taken into account
	var target_angle = player.weapon_aim_angle(target_player.position - player.position)

	var half_subtended = half_subtended(target_player)
	var angle_diff = Math.shortest_angle_between(raw_angle, target_angle)
	# start_diff is the angle difference where the influence of auto aim starts to take effect
	# the maximum half-subtended angle is roughly 0.5. A width of 8 was chosen by inspection with this in mind.
	var start_diff = half_subtended * ((max_start_diff_multiply-1)*exp(-8*half_subtended)+1)
	# a correction of -angle_diff will result in aiming directly at the target player's position
	var correction = -angle_diff * auto_aim_influence(raw_angle, half_subtended, angle_diff, start_diff)

	#var dd = G.get_scene().debug_draw
	#var n = player.config.num
	##var p = player.position
	#var p = player.current_weapon.get_node('Muzzle').global_position
	#var l = 5.0 # lifetime (seconds)
	#dd.add_line_segment(p+polar2cartesian(200, target_angle-half_subtended), p, l, 'aa1_%s' % n)
	#dd.add_line_segment(p+polar2cartesian(200, target_angle+half_subtended), p, l, 'aa2_%s' % n)
	#dd.add_line_segment(p+polar2cartesian(200, target_angle-start_diff), p, l, 'aa3_%s' % n, Color('#ffff00ff'))
	#dd.add_line_segment(p+polar2cartesian(200, target_angle+start_diff), p, l, 'aa4_%s' % n, Color('#ffff00ff'))

	#dd.add_line_segment(p+polar2cartesian(250, target_angle), p, l, 'aa8_%s' % n, Color('#ffffffff'))
	#dd.add_line_segment(p+polar2cartesian(200, raw_angle), p, l, 'aa5_%s' % n, Color('#ff0000ff'))
	#dd.add_line_segment(p+polar2cartesian(1000, raw_angle+correction), p, l, 'aa6_%s' % n, Color('#ff000000'))

	return raw_angle + correction

# the angle that the target player subtends at the location of this player
func half_subtended(target_player):
	var to_target = target_player.position - player.position
	var hitbox = target_player.get_node('HitBox').shape
	var r = hitbox.height/2 + hitbox.radius # approximate the capsule hitbox using a circle (less accurate when above or below)
	var half_subtended = atan(r/to_target.length()) # don't need atan2 since the quadrant doesn't matter
	return half_subtended

func auto_aim_influence(raw_angle, half_subtended, angle_diff, start_diff):
	# solve for the width which results in an output of start_influence at an angle difference of start_diff
	# this could be cached but the other parameters might be changed making the cached value wrong
	var width = -log(start_influence/max_influence)/pow(start_diff, power) # log is natural logarithm
	return max_influence*exp(-width*pow(angle_diff, power))

