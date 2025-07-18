extends CharacterBody2D

# --- Designer knobs ---------------------------------------------------------
@export var show_debug_path: bool = true

# Preview
const BOOST_IMPULSE: float = 200.0
const GRAV_SCALE: float = 2.0	# global tuning knob
const GRAVITY_EXPONENT: float = 1.2  # 1 = slow fall-off, 2 = inverse-square

const PRED_TIME: float = 3.0
const PRED_STEPS: int = 5

# --- Runtime state ----------------------------------------------------------
var planets: Array = []		# injected by solar_system.gd
var lin_vel: Vector2 = Vector2.ZERO


## Continuous thrust handled each physics tick --------------------------------
## Keys held down apply constant acceleration, giving smooth steering.

func _ready():
	var r_vec: Vector2 = global_position
	var r: float = r_vec.length()
	if r > 0.0:
		var tangential: Vector2 = Vector2(-r_vec.y, r_vec.x).normalized()
		lin_vel = tangential * sqrt(5.0e4 / r) * 10

func _physics_process(dt: float) -> void:
	# Player thrust
	var thrust: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("left"):
		thrust.x -= 1
	if Input.is_action_pressed("right"):
		thrust.x += 1
	if Input.is_action_pressed("up"):
		thrust.y -= 1
	if Input.is_action_pressed("down"):
		thrust.y += 1
	if thrust != Vector2.ZERO:
		lin_vel += thrust.normalized() * BOOST_IMPULSE * dt
	lin_vel += _gravity_accel_at() * dt
	# Clamp velocity components to ±1000 to avoid extreme speeds
	lin_vel = lin_vel.clamp(Vector2(-1500, -1500), Vector2(1500, 1500))
	global_position += lin_vel * dt

	if show_debug_path:
		queue_redraw()

# ------------------------------------------------------------------
func _gravity_accel_at() -> Vector2:
	var total_acceleration: Vector2 = Vector2.ZERO
	for planet in planets:
		var vector_to_planet: Vector2 = planet.global_position - global_position
		# Use distance (not squared) and a tunable exponent for softer fall-off
		var distance: float = max(1.0, vector_to_planet.length())
		var strength: float = (planet.gravity / pow(distance, GRAVITY_EXPONENT)) * GRAV_SCALE
		total_acceleration += vector_to_planet.normalized() * strength
	return total_acceleration

# ------------------------------------------------------------------
func _draw():
	if !show_debug_path:
		return

	var simulated_position: Vector2 = global_position
	var simulated_velocity: Vector2 = lin_vel
	var delta_time: float = PRED_TIME / PRED_STEPS

	# snapshot planets
	var simulated_planet_positions: Array = []
	var simulated_planet_velocities: Array = []
	for planet in planets:
		simulated_planet_positions.append(planet.global_position)
		simulated_planet_velocities.append(planet.vel)

	var dot_radius: float = 2.0
	for _step in range(PRED_STEPS):
		var total_gravity: Vector2 = Vector2.ZERO
		for index in range(simulated_planet_positions.size()):
			# vector from ship to planet
			var vector_to_planet: Vector2 = simulated_planet_positions[index] - simulated_position
			var distance: float = max(1.0, vector_to_planet.length())
			# gravity toward this planet
			var strength: float = (planets[index].gravity / pow(distance, GRAVITY_EXPONENT)) * GRAV_SCALE
			total_gravity += vector_to_planet.normalized() * strength

			# advance planet one step (sun-centric two-body)
			var planet_acceleration: Vector2 = -5.0e4 * simulated_planet_positions[index] / pow(distance, 1.5)
			simulated_planet_velocities[index] += planet_acceleration * delta_time
			simulated_planet_positions[index] += simulated_planet_velocities[index] * delta_time
		# end planet loop

		# advance ship
		simulated_velocity += total_gravity * delta_time
		simulated_position += simulated_velocity * delta_time
		draw_circle(to_local(simulated_position), dot_radius, Color.YELLOW)
	# end step loop
