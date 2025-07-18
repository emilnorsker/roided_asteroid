extends Node2D

@onready var sun = $Sun
var planet_scene = preload("res://Planet.tscn")

func _ready():
	var tex_sun = preload("res://assets/sun.png")
	var tex_planet_1 = preload("res://assets/earth.png")
	var tex_planet_2 = preload("res://assets/not_earth.png")

	# Positional argument calls:
	sun = create_planet(25.0, 1.0, 200.0, 150.0, 1, tex_sun, null, false)
	create_planet(200.0, 0.7, 200.0, 100.0, 2, tex_planet_1, sun, false)
	create_planet(300.0, 0.5, 50.0, 200.0, 2, tex_planet_2, sun, false)



func create_planet(orbit_radius: float, orbit_speed: float, planet_radius: float, soi_radius: float, grav_prio: int, texture: Texture2D, grav_center=null, desctuctible=false):
	var planet = planet_scene.instantiate()

	planet.orbit_radius = orbit_radius
	planet.orbit_speed = orbit_speed
	planet.planet_radius = planet_radius
	planet.soi_radius = soi_radius
	if (grav_center != null):
		planet.orbit_center = grav_center
	else:
		planet.orbit_center =  self
	planet.gravity_prio = grav_prio
	planet.is_destructible = desctuctible
	planet.get_node("Sprite2D").texture = texture
	add_child(planet)
	return planet
