extends CharacterBody2D

# --- Designer knobs ---------------------------------------------------------
@export var show_debug_path: bool = true

# Preview
const BOOST_IMPULSE: float = 50.0
const GRAV_SCALE: float = 2.0	# global tuning knob

const PRED_TIME: float = 30.0
const PRED_STEPS: int = 60

# --- Runtime state ----------------------------------------------------------
var planets: Array = []		# injected by solar_system.gd
var lin_vel: Vector2 = Vector2.ZERO


func _unhandled_input(ev):
	if ev.is_action_pressed("space") and lin_vel.length() > 0.0:
		lin_vel += lin_vel.normalized() * BOOST_IMPULSE

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # immersive
	# give the player an initial circular-orbit velocity around the sun (origin)
	var r_vec: Vector2 = global_position
	var r: float = r_vec.length()
	if r > 0.0:
		var tangential: Vector2 = Vector2(-r_vec.y, r_vec.x).normalized()
		lin_vel = tangential * sqrt(5.0e4 / r) * 10

func _physics_process(dt: float) -> void:
	lin_vel += _gravity_accel_at(global_position) * dt
	# Clamp velocity components to ±1000 to avoid extreme speeds
	lin_vel = lin_vel.clamp(Vector2(-500, -500), Vector2(500, 500))
	global_position += lin_vel * dt

	if show_debug_path:
		queue_redraw()

# ------------------------------------------------------------------
func _gravity_accel_at(pos: Vector2) -> Vector2:
	var g: Vector2 = Vector2.ZERO
	for p in planets:
		var to_p: Vector2 = p.global_position - pos
		var dist_sq: float = max(1.0, to_p.length_squared())
		g += to_p.normalized() * (p.gravity / dist_sq) * GRAV_SCALE
	return g

# ------------------------------------------------------------------
func _draw():
	if !show_debug_path:
		return
	var sim_pos: Vector2 = global_position
	var sim_vel: Vector2 = lin_vel
	var dt: float = PRED_TIME / PRED_STEPS

	# clone planet states
	var sim_plan_pos: Array = []
	var sim_plan_vel: Array = []
	for p in planets:
		sim_plan_pos.append(p.global_position)
		sim_plan_vel.append(p.vel)

	var dot_r: float = 2.0
	for step in range(PRED_STEPS):
		# compute gravity at current simulated player pos using sim planet positions
		var g: Vector2 = Vector2.ZERO
		for idx in range(sim_plan_pos.size()):
			var to_p: Vector2 = sim_plan_pos[idx] - sim_pos
			var dist_sq: float = max(1.0, to_p.length_squared())
			g += to_p.normalized() * (planets[idx].gravity / dist_sq) * GRAV_SCALE
		# sun (index 0) already included if grav param set
		
		sim_vel += g * dt
		sim_pos += sim_vel * dt
		draw_circle(to_local(sim_pos), dot_r, Color.YELLOW)

		# advance simulated planets (central sun gravity only)
		for idx in range(sim_plan_pos.size()):
			# acceleration toward origin for each planet
			var r: Vector2 = sim_plan_pos[idx]
			var dist_sq_p: float = max(1.0, r.length_squared())
			var acc_p: Vector2 = -5.0e4 * r / pow(dist_sq_p, 1.5)
			sim_plan_vel[idx] += acc_p * dt
			sim_plan_pos[idx] += sim_plan_vel[idx] * dt
