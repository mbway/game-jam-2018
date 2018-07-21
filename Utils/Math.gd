extends Node

static func random_normal(mu, sigma):
	# Box-Muller transform
	
	# two samples from U(0,1)
	var a = randf()
	var b = randf()
	
	# log is natural logarithm
	# a second normally distributed value could be generated by using sine
	var c = sqrt(-2*log(a))*cos(2*PI*b)
	return c*sigma + mu

static func positive_modulo(a, b):
	return (a % b + b) % b