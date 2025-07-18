extends Node2D

const MU_SUN: float = 5.0e4

var planet_scene = preload("res://planet.tscn")
var planets: Array = []

func _ready():
	# Spawn sun as a planet at the origin (stationary)
	var sun = _spawn_planet(0.0, "res://assets/sun.png")
	sun.vel = Vector2.ZERO
	sun.gravity = 80_000.0

	# radius (px) and texture path pairs for regular planets
	var defs = [
		{"r": 200.0, "tex": "res://assets/earth.png"},
		{"r": 620.0, "tex": "res://assets/not_earth.png"},
		{"r": 350.0, "tex": "res://assets/not_earth.png"},
		{"r": 820.0, "tex": "res://assets/earth.png"},
		{"r": 950.0, "tex": "res://assets/not_earth.png"},
	]

	for d in defs:
		#pass
		_spawn_planet(d.r, d.tex)
	# hand the list to the player for gravity / capture tests
	var player = $Player
	player.planets = planets

func _spawn_planet(radius: float, tex_path: String):
	var planet = planet_scene.instantiate()
	var pos_x = 1 if randf() > 0.5 else -1
	var pos_y = 1 if randf() > 0.5 else -1
	planet.global_position = Vector2(radius * pos_x, radius* randf() * pos_y)

	var speed = 0.0
	if radius > 0.0:
		speed = sqrt(MU_SUN / radius)
	planet.vel = Vector2(0, speed)  # tangent +Y
	
	planet.get_node("Sprite2D").texture = load(tex_path)

	planets.append(planet)
	add_child(planet)
	return planet
