extends Node2D

@onready var sun = $Sun
var planet_scene = preload("res://Planet.tscn")

func _ready():
	var tex_sun = preload("res://assets/earth.aseprite")
	var tex_planet_1 = preload("res://assets/earth.aseprite")
	var tex_planet_2 = preload("res://assets/not_earth.aseprite")

	# Positional argument calls:
	create_planet(300, 1.0, 32, 150, 1, tex_sun)
	create_planet(450, 0.7, 24, 120, 2, tex_planet_1)
	create_planet(600, 0.5, 40, 200, 2, tex_planet_2)



func create_planet(orbit_radius: float, orbit_speed: float, planet_radius: float, soi_radius: float, grav_prio: int, texture: Texture2D):
	var planet = planet_scene.instantiate()
	add_child(planet)

	planet.orbit_radius = orbit_radius
	planet.orbit_speed = orbit_speed
	planet.planet_radius = planet_radius
	planet.soi_radius = soi_radius
	planet.orbit_center = sun.get_path()
	planet.gravity_prio = grav_prio

	planet.get_node("Sprite2D").texture = texture
