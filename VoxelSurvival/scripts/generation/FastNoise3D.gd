class_name FastNoise3D
extends RefCounted

## Simple 3D noise implementation for cave generation
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

func grad(hash: int, x: float, y: float, z: float) -> float:
	var h = hash & 15
	var u = x if h < 8 else y
	var v = y if h < 4 else (z if h != 12 and h != 14 else x)
	if h & 1:
		u = -u
	if h & 2:
		v = -v
	return u + v

func noise3d(x: float, y: float, z: float) -> float:
	# Grid cell coordinates
	var xi = floori(x)
	var yi = floori(y)
	var zi = floori(z)
	
	# Relative position within cell
	var xf = x - xi
	var yf = y - yi
	var zf = z - zi
	
	# Fade curves
	var u = fade(xf)
	var v = fade(yf)
	var w = fade(zf)
	
	# Hash coordinates of cell corners
	var aaa = permutation[permutation[permutation[xi & 255] + (yi & 255)] + (zi & 255)]
	var aab = permutation[permutation[permutation[xi & 255] + (yi & 255)] + ((zi + 1) & 255)]
	var aba = permutation[permutation[permutation[xi & 255] + ((yi + 1) & 255)] + (zi & 255)]
	var abb = permutation[permutation[permutation[xi & 255] + ((yi + 1) & 255)] + ((zi + 1) & 255)]
	var baa = permutation[permutation[permutation[(xi + 1) & 255] + (yi & 255)] + (zi & 255)]
	var bab = permutation[permutation[permutation[(xi + 1) & 255] + (yi & 255)] + ((zi + 1) & 255)]
	var bba = permutation[permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)] + (zi & 255)]
	var bbb = permutation[permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)] + ((zi + 1) & 255)]
	
	# Blend results from corners
	var x1 = lerp(grad(aaa, xf, yf, zf), grad(baa, xf-1, yf, zf), u)
	var x2 = lerp(grad(aab, xf, yf, zf-1), grad(bab, xf-1, yf, zf-1), u)
	var x3 = lerp(grad(aba, xf, yf-1, zf), grad(bba, xf-1, yf-1, zf), u)
	var x4 = lerp(grad(abb, xf, yf-1, zf-1), grad(bbb, xf-1, yf-1, zf-1), u)
	
	var y1 = lerp(x1, x2, v)
	var y2 = lerp(x3, x4, v)
	
	return lerp(y1, y2, w)

func octave_noise(x: float, y: float, z: float, octaves: int = 3, persistence: float = 0.5) -> float:
	var total = 0.0
	var frequency = 1.0
	var amplitude = 1.0
	var max_value = 0.0
	
	for i in range(octaves):
		total += noise3d(x * frequency, y * frequency, z * frequency) * amplitude
		max_value += amplitude
		frequency *= 2.0
		amplitude *= persistence
	
	return total / max_value

func set_seed(s: int):
	seed_value = s
	generate_permutation()
