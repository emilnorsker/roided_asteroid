extends Node2D


var planet_scene = preload("res://planet.tscn")
var satellite_scene = preload("res://satellite.tscn")

var planets: Array = []

const PLANET_BASE_RADIUS := 58.0       # sprite / collision radius before scaling
const MAX_SPAWN_RADIUS   := 1500.0     # distance from Sun centre
const MIN_SPAWN_RADIUS   := 150.0      # keep them out of the Sun sprite
const MAX_SPAWN_ATTEMPTS := 40         # safety-net to avoid infinite loops

# textures we can pick from
var planet_textures := [
	"res://assets/earth.png",
	"res://assets/not_earth.png"
]

func _ready():
	for _i in range(10):
		var tex_path: String = planet_textures.pick_random()
		_spawn_planet_no_overlap(tex_path)

	var player = $Player
	player.planets = planets
	set_fx()


func _find_free_position(new_radius: float) -> Vector2:
	var tries: int = 0
	
	while tries < MAX_SPAWN_ATTEMPTS:
		# random radius & angle around the Sun
		var r: float = randf_range(MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS)
		var angle: float = randf() * PI * 2.0
		var pos: Vector2 = Vector2(cos(angle), sin(angle)) * r

		var ok: bool = true
		for p in planets:
			var other_r: float = PLANET_BASE_RADIUS * p.scale.x
			if pos.distance_to(p.global_position) < new_radius + other_r:
				ok = false
				break
		if pos.distance_to($Player.global_position) < 100:
			ok = false
		if ok:
			return pos
		tries += 1
	push_warning("Could not find non-overlapping spot after %d tries" % tries)
	return Vector2.ZERO   # fallback – may overlap

func _spawn_planet_no_overlap(tex_path: String):
	var planet = planet_scene.instantiate()

	# you can randomise scale if desired; here we keep it 1
	planet.set_new_scale(randf_range(0.5, 3.5))
	var eff_radius: float = PLANET_BASE_RADIUS * planet.scale.x

	planet.global_position = _find_free_position(eff_radius)
	_init_planet_dynamics(planet)
	planet.get_node("Sprite2D").texture = load(tex_path)
	_spawn_satellites(planet, randi() % 3 + 1)
	planets.append(planet)
	add_child(planet)

func _init_planet_dynamics(planet: RigidBody2D):
	planet.linear_damp = 0.0
	# Enable interaction with the Sun’s Area2D gravity.
	planet.gravity_scale = 1.0
	var radius = planet.global_position.distance_to($Sun.global_position)
	var sun_area: Area2D = $Sun/InfluenceCircle

	# 2) Use the same μ that Godot uses internally: μ = g * scale * d₀²
	var mu: float = sun_area.gravity \
		* planet.gravity_scale \
		* pow(sun_area.gravity_point_unit_distance, 2) 

	# Circular-orbit speed.
	var speed: float = sqrt(mu / radius)

	var tangent_dir: Vector2 = Vector2(-planet.global_position.y, planet.global_position.x).normalized()
	planet.linear_velocity = tangent_dir * speed

func _spawn_satellites(planet: Node2D, count: int):
	for i in count:
		var sat = preload("res://satellite.tscn").instantiate()
		sat.center_node = planet
		sat.orbit_radius = 80.0 + randf_range(10.0, 120.0)
		sat.orbit_speed = randf_range(0.5, 1.5)

		# Choose texture based on planet texture
		var tex_path = planet.get_node("Sprite2D").texture.resource_path
		#if "earth.png" in tex_path:
			#sat.get_node("Sprite2D").texture = preload("res://assets/satelite_1.png")
		#else:
			#sat.get_node("Sprite2D").texture = preload("res://assets/satelite_2.png")

		add_child(sat)


	planets.append(planet)



func set_fx():
	var fx: PostFx = $PostFX
	var crt: CRTShaderFX = fx.effects[0]
	crt.resolution = Vector2(1920.0, 1080.0)
	crt.roll = false
	crt.roll_size = 0
	crt.aberration = 0.001
	crt.scanlines_opacity = 0.02
	crt.grille_opacity = 0.002
	crt.warp_amount	= 0.8
	crt.distort_intensity = 0
	crt.noise_opacity = 0
	crt.static_noise_intensity = 0.1
	crt.pixelate = false
