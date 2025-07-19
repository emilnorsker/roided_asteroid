extends Node2D


var planet_scene = preload("res://planet.tscn")
var planets: Array = []

func _ready():
	# Configure Sun's gravity influence programmatically to guarantee correct values
	var area: Area2D = $Sun/InfluenceCircle
	area.gravity_point = true      # strong central pull
	area.gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE
	# radius (px) and texture path pairs for regular planets
	var defs = [
		{"r": 200.0, "tex": "res://assets/earth.png"},
		{"r": 620.0, "tex": "res://assets/not_earth.png"},
		{"r": 350.0, "tex": "res://assets/not_earth.png"},
		{"r": 820.0, "tex": "res://assets/earth.png"},
		{"r": 950.0, "tex": "res://assets/not_earth.png"},
		{"r": 500.0, "tex": "res://assets/not_earth.png"},
		{"r": 250.0, "tex": "res://assets/not_earth.png"},
		{"r": 800.0, "tex": "res://assets/earth.png"},
		{"r": 1100.0, "tex": "res://assets/earth.png"},
		{"r": 1200.0, "tex": "res://assets/not_earth.png"},
		{"r": 1400.0, "tex": "res://assets/not_earth.png"},
		{"r": 1600.0, "tex": "res://assets/earth.png"},
		{"r": 1800.0, "tex": "res://assets/not_earth.png"},
		{"r": 2000.0, "tex": "res://assets/not_earth.png"},
		{"r": 1200.0, "tex": "res://assets/earth.png"},
		{"r": 2400.0, "tex": "res://assets/not_earth.png"},
		# {"r": 1650.0, "tex": "res://assets/not_earth.png"},
		# {"r": 1880.0, "tex": "res://assets/earth.png"},
		# {"r": 2500.0, "tex": "res://assets/not_earth.png"},
		# {"r": 320.0, "tex": "res://assets/not_earth.png"},
		# {"r": 340.0, "tex": "res://assets/earth.png"},
		# {"r": 1200.0, "tex": "res://assets/not_earth.png"}
	]

	for d in defs:
		# pass
		_spawn_planet(d.r, d.tex)
	# hand the list to the player for gravity / capture tests
	var player = $Player
	player.planets = planets
	
	set_fx()

func _spawn_planet(radius: float, tex_path: String):
	var planet = planet_scene.instantiate()
	var pos_x = 1 if randf() > 0.5 else -1
	var pos_y = 1 if randf() > 0.5 else -1
	planet.global_position = Vector2(radius * pos_x, radius* randf() * pos_y)
	planet.linear_damp = 0.0

	# Initial tangential speed for (approx.) circular orbit
	var r_vec: Vector2 = planet.global_position
	var r_len: float = max(1.0, r_vec.length())
	var sun_area: Area2D = $Sun/InfluenceCircle
	var unit_d := sun_area.gravity_point_unit_distance
	var mu := sun_area.gravity * unit_d * unit_d   # effective G*My
	var scale: float = planet.gravity_scale
	if scale <= 0:
		#scale = 1.0
		pass
	var speed: float = sqrt(mu * scale / r_len)    # circular orbit speed adjusted
	# Optional scaling factor to exaggerate orbits
	# speed *= 1.0
	# Tangential direction is 90° rotated (-y, x)
	var tangent_dir: Vector2 = Vector2(-r_vec.y, r_vec.x).normalized()
	planet.linear_velocity = tangent_dir * speed
	
	planet.get_node("Sprite2D").texture = load(tex_path)

	planets.append(planet)
	add_child(planet)
	return planet

func set_fx():
	var fx: PostFx = $PostFX
	var crt: CRTShaderFX = fx.effects[0]
	crt.resolution = Vector2(1920.0, 1080.0)

	crt.roll = false
	crt.roll_size = 0
	crt.aberration = 0.01
	crt.scanlines_opacity = 0.02
	crt.grille_opacity = 0.002
	crt.warp_amount	= 0.8
	crt.distort_intensity = 0
	crt.noise_opacity = 0
