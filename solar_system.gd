extends Node2D


var planet_scene = preload("res://planet.tscn")
var satellite_scene = preload("res://satellite.tscn")

var planets: Array = []

# NEW – reference to the ColorRect that hosts the shockwave shader
var _shockwave_rect: ColorRect

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
	_setup_shockwave()   # NEW



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
	planet.set_new_scale(randf_range(0.5, 2.5))
	var eff_radius: float = PLANET_BASE_RADIUS * planet.scale.x

	planet.global_position = _find_free_position(eff_radius)
	_init_planet_dynamics(planet)
	planet.get_node("Sprite2D").texture = load(tex_path)
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


func set_fx():
	var fx: PostFx = $PostFX
	var crt: CRTShaderFX = fx.effects[0]
	crt.resolution = Vector2(1280.0, 960.0)
	crt.roll = false
	crt.roll_size = 0
	crt.aberration = 0.01
	crt.scanlines_opacity = 0.00
	crt.grille_opacity = 0.000
	crt.warp_amount	= 0.8
	crt.distort_intensity = 0.0
	crt.noise_opacity = 0
	crt.static_noise_intensity = 0.1
	crt.pixelate = true

# ------------------------------------------------------------------
# Shock-wave screen-space effect
# ------------------------------------------------------------------
func _setup_shockwave():
	# Create a CanvasLayer so the effect is drawn on top of gameplay
	var layer := CanvasLayer.new()
	layer.name = "ShockwaveLayer"
	add_child(layer)

	var rect := ColorRect.new()
	rect.name = "Shockwave"
	rect.color = Color.WHITE
	rect.visible = false
	rect.anchor_left = 0
	rect.anchor_top = 0
	rect.anchor_right = 1
	rect.anchor_bottom = 1
	rect.position = Vector2.ZERO
	rect.size = get_viewport().get_visible_rect().size

	var mat := ShaderMaterial.new()
	mat.shader = load("res://fx/shockwave.gdshader")
	rect.material = mat
	# Make the effect stronger by default
	mat.set_shader_parameter("strength", 0.12)
	mat.set_shader_parameter("width", 0.1)

	layer.add_child(rect)
	_shockwave_rect = rect

func trigger_shockwave(world_pos: Vector2):
	if _shockwave_rect == null:
		return
	var cam := get_viewport().get_camera_2d()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_pos: Vector2
	if cam:
		var cam_pos: Vector2 = cam.global_position
		var zoom: Vector2 = cam.zoom
		screen_pos = (world_pos - cam_pos) * zoom + vp_size * 0.5
	else:
		screen_pos = world_pos
	var uv: Vector2 = screen_pos / vp_size

	var mat: ShaderMaterial = _shockwave_rect.material as ShaderMaterial
	mat.set_shader_parameter("center", uv)
	mat.set_shader_parameter("radius", 0.05)

	_shockwave_rect.visible = true

	var t := create_tween()
	# Grow a bit larger and slower for a punchier feel
	const FINAL_RADIUS := 0.2
	const DURATION := 0.3
	t.tween_property(mat, "shader_parameter/radius", FINAL_RADIUS, DURATION)
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(Callable(_shockwave_rect, "hide"))

func trigger_slowmo(duration: float = 0.3, scale: float = 0.15):
	Engine.time_scale = scale
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.ignore_time_scale = true
	timer.connect("timeout", Callable(self, "_on_slowmo_finished"))
	add_child(timer)
	timer.start()

func _on_slowmo_finished():
	Engine.time_scale = 1.0
