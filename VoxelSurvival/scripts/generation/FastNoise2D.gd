class_name FastNoise2D
extends RefCounted

## Simple 2D noise implementation for terrain generation
## Based on Perlin noise algorithm

var permutation: Array = []
var seed_value: int = 12345

func _init(s: int = 12345):
	seed_value = s
	generate_permutation()

func generate_permutation():
	permutation.clear()
	permutation.resize(512)
	
	# Create identity permutation
	var p: Array = []
	p.resize(256)
	for i in range(256):
		p[i] = i
	
	# Shuffle based on seed
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	for i in range(255, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = p[i]
		p[i] = p[j]
		p[j] = temp
	
	# Duplicate for overflow handling
	for i in range(256):
		permutation[i] = p[i]
		permutation[i + 256] = p[i]

func fade(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t

func grad(hash: int, x: float, y: float) -> float:
	var h = hash & 3
	var u = x if h < 2 else y
	var v = y if h < 2 else x
	if h & 1:
		u = -u
	if h & 2:
		v = -v
	return u + v

func noise2d(x: float, y: float) -> float:
	# Grid cell coordinates
	var xi = floori(x)
	var yi = floori(y)
	
	# Relative position within cell
	var xf = x - xi
	var yf = y - yi
	
	# Fade curves
	var u = fade(xf)
	var v = fade(yf)
	
	# Hash coordinates of cell corners
	var aa = permutation[permutation[xi & 255] + (yi & 255)]
	var ab = permutation[permutation[xi & 255] + ((yi + 1) & 255)]
	var ba = permutation[permutation[(xi + 1) & 255] + (yi & 255)]
	var bb = permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)]
	
	# Blend results from corners
	var x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1.0, yf), u)
	var x2 = lerp(grad(ab, xf, yf - 1.0), grad(bb, xf - 1.0, yf - 1.0), u)
	
	return lerp(x1, x2, v)

func octave_noise(x: float, y: float, octaves: int = 4, persistence: float = 0.5) -> float:
	var total = 0.0
	var frequency = 1.0
	var amplitude = 1.0
	var max_value = 0.0
	
	for i in range(octaves):
		total += noise2d(x * frequency, y * frequency) * amplitude
		max_value += amplitude
		frequency *= 2.0
		amplitude *= persistence
	
	return total / max_value

func set_seed(s: int):
	seed_value = s
	generate_permutation()
